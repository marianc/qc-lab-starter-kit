using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using System.Text.Json;
using System.Globalization;
using QCLab.Utils;
using QCFormula;

namespace QCLab.Services;

public class MeasurementsService : IMeasurementsService
{
    private readonly QualityControlContext _context;
    private readonly IFormsService _formsService;

    public MeasurementsService(QualityControlContext context, IFormsService formsService)
    {
        _context = context;
        _formsService = formsService;
    }

    private async Task<MeasurementTestDetailDto?> GetMeasurementTestData(long measurementId)
    {
        var measurement = await _context.Measurements
            .Include(m => m.UserUpdate)
            .Include(m => m.UserReported)
            .FirstOrDefaultAsync(m => m.Id == measurementId);

        if (measurement != null)
        {
            var dto = new MeasurementTestDetailDto
            {
                Id = measurement.Id,
                ReceptionId = measurement.ReceptionId,
                Comments = measurement.Comments,
                UseDefaultEquipment = measurement.UseDefaultEquipment,
                IsReported = measurement.IsReported,
                IsReadonly = measurement.IsReadonly,
                UserUpdateId = measurement.UserUpdateId,
                UserUpdateTag = measurement.UserUpdate.Tag,
                UserReportedTag = measurement.UserReported?.Tag,
                DateUpdate = measurement.DateUpdate,
                Tests = new List<MeasurementTestDto>()
            };

            var testsRows = await _context.MeasurementTests
                .Include(mt => mt.Test)
                .Where(mt => mt.MeasurementId == measurementId)
                .OrderBy(mt => mt.TestId)
                .ThenBy(mt => mt.Idx)
                .ToListAsync();

            var testsGrouped = testsRows.GroupBy(t => t.TestId);
            foreach (var group in testsGrouped)
            {
                var first = group.First();
                var isArray = first.Test.IsArray;
                object finalValue;
                
                if (isArray)
                {
                    finalValue = group.Select(g => g.Value).ToList();
                }
                else
                {
                    finalValue = group.Any() ? group.First().Value : 0;
                }

                dto.Tests.Add(new MeasurementTestDto
                {
                    TestId = first.TestId,
                    Note = first.Note,
                    Value = finalValue
                });
            }

            return dto;
        }
        return null;
    }

    private async Task<MeasurementParamDetailDto?> GetMeasurementParamData(long measurementId)
    {
        var measurement = await _context.Measurements
            .Include(m => m.UserUpdate)
            .Include(m => m.UserReported)
            .FirstOrDefaultAsync(m => m.Id == measurementId);

        if (measurement != null && measurement.FormId.HasValue)
        {
            var dto = new MeasurementParamDetailDto
            {
                Id = measurement.Id,
                ReceptionId = measurement.ReceptionId,
                FormId = measurement.FormId.Value,
                Comments = measurement.Comments,
                UseDefaultEquipment = measurement.UseDefaultEquipment,
                IsReported = measurement.IsReported,
                IsReadonly = measurement.IsReadonly,
                UserUpdateId = measurement.UserUpdateId,
                UserUpdateTag = measurement.UserUpdate.Tag,
                UserReportedTag = measurement.UserReported?.Tag,
                DateUpdate = measurement.DateUpdate,
                MeasurementData = new Dictionary<string, object?>(),
                CalculatedResults = new Dictionary<string, object?>()
            };

            var formId = measurement.FormId.Value;
            var formParamsSchema = await _formsService.GetFormParams(formId);

            var measurementParams = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == measurementId && mp.FormId == formId)
                .ToListAsync();

            var flatParams = measurementParams.Select(mp => new MeasurementFlatData { TestId = mp.TestId, Idx = mp.Idx, Value = mp.Value }).ToList();
            var allDataDict = FormEvalMapper.MapFlatToDict(flatParams, formParamsSchema);

            foreach (var param in formParamsSchema)
            {
                object? value = allDataDict.TryGetValue(param.Code, out var val) ? val : null;
                if (value == null && !param.IsCalculated) value = param.DefaultValue;

                if (param.IsCalculated) dto.CalculatedResults[param.Code] = value;
                else dto.MeasurementData[param.Code] = value;
            }

            return dto;
        }
        return null;
    }

    // GET /measurement_tests/{id}
    public async Task<MeasurementTestDetailDto?> GetMeasurementTest(long id)
    {
        return await GetMeasurementTestData(id);
    }

    // GET /measurement_params/{id}
    public async Task<MeasurementParamDetailDto?> GetMeasurementParam(long id)
    {
        return await GetMeasurementParamData(id);
    }

    // POST /measurements
    public async Task<IdDto> CreateMeasurement(CreateMeasurementDto dto, long userId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = new Measurement
            {
                ReceptionId = dto.ReceptionId,
                Comments = dto.Comments,
                UseDefaultEquipment = true,
                IsReported = dto.IsReported,
                FormId = dto.FormId,
                UserCreatedId = userId,
                UserUpdateId = userId,
                DateUpdate = DateTime.UtcNow
            };

            _context.Measurements.Add(measurement);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return new() { Id = measurement.Id };
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // PUT /measurement_tests/{id}
    public async Task UpdateMeasurementTest(long id, UpdateMeasurementTestBulkDto dto, long userId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement == null) throw new ArgumentException("Measurement not found");

            measurement.Comments = dto.Comments;
            measurement.UseDefaultEquipment = dto.UseDefaultEquipment;
            measurement.IsReported = false;
            measurement.UserReportedId = null;
            measurement.DateReported = null;
            measurement.UserUpdateId = userId;
            measurement.DateUpdate = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            if (dto.Tests != null)
            {
                var existingTests = await _context.MeasurementTests.Where(mt => mt.MeasurementId == id).ToListAsync();
                _context.MeasurementTests.RemoveRange(existingTests);
                await _context.SaveChangesAsync();

                foreach (var testDto in dto.Tests)
                {
                    var testInfo = await _context.Tests.FindAsync(testDto.TestId);
                    var isArray = testInfo?.IsArray ?? false;

                    if (isArray && testDto.Value != null)
                    {
                        var values = new List<decimal>();
                        if (testDto.Value is JsonElement je && je.ValueKind == JsonValueKind.Array)
                        {
                            foreach (var item in je.EnumerateArray())
                            {
                                if (item.TryGetDecimal(out decimal val)) values.Add(val);
                                else if (decimal.TryParse(item.GetString(), out decimal vals)) values.Add(vals);
                            }
                        }
                        else if (testDto.Value is IEnumerable<decimal> doubleEnum) values.AddRange(doubleEnum);
                        else if (testDto.Value is string s)
                        {
                            values = s.Split(',').Select(v => decimal.TryParse(v.Trim(), out decimal val) ? val : 0.0m).ToList();
                        }

                        for (int i = 0; i < values.Count; i++)
                        {
                            _context.MeasurementTests.Add(new MeasurementTest
                            {
                                MeasurementId = id,
                                TestId = testDto.TestId,
                                Idx = i,
                                Value = values[i],
                                Note = testDto.Note
                            });
                        }
                    }
                    else if (!isArray && testDto.Value != null)
                    {
                        decimal val = 0;
                        if (testDto.Value is JsonElement je && je.ValueKind == JsonValueKind.Number) val = je.GetDecimal();
                        else if (testDto.Value is JsonElement jes && jes.ValueKind == JsonValueKind.String) decimal.TryParse(jes.GetString(), out val);
                        else if (decimal.TryParse(testDto.Value.ToString(), out decimal parsedVal)) val = parsedVal;

                        _context.MeasurementTests.Add(new MeasurementTest
                        {
                            MeasurementId = id,
                            TestId = testDto.TestId,
                            Idx = 0,
                            Value = val,
                            Note = testDto.Note
                        });
                    }
                }
                await _context.SaveChangesAsync();
            }

            if (dto.UseDefaultEquipment)
            {
                await RecalculateMeasurementEquipments(id);
            }

            await RecalculateMeasurementSopVersions(id);
            await RecalculateMeasurementReagentLots(id);

            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    public async Task UpdateMeasurementParam(long id, UpdateMeasurementParamDto dto, long userId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement == null) throw new ArgumentException("Measurement not found");

            measurement.Comments = dto.Comments;
            measurement.UseDefaultEquipment = dto.UseDefaultEquipment;
            measurement.IsReported = dto.IsReported;
            measurement.UserUpdateId = userId;
            measurement.DateUpdate = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await SaveMeasurementFormDataInternal(id, dto.MeasurementData);

            if (dto.UseDefaultEquipment)
            {
                await RecalculateMeasurementEquipments(id);
            }

            await RecalculateMeasurementSopVersions(id);
            await RecalculateMeasurementReagentLots(id);

            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    // DELETE /measurements/{id}
    public async Task DeleteMeasurement(long id)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var tests = await _context.MeasurementTests.Where(mt => mt.MeasurementId == id).ToListAsync();
            _context.MeasurementTests.RemoveRange(tests);

            var params_ = await _context.MeasurementParams.Where(mp => mp.MeasurementId == id).ToListAsync();
            _context.MeasurementParams.RemoveRange(params_);

            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement != null)
            {
                _context.Measurements.Remove(measurement);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    // PUT /measurements/{id}/toggle_reported
    public async Task ToggleReported(long id, long userId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement == null) throw new ArgumentException("Measurement not found");

            if (measurement.IsReported)
            {
                measurement.IsReported = false;
                measurement.UserReportedId = null;
                measurement.DateReported = null;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return;
            }

            if (!measurement.FormId.HasValue)
            {
                measurement.IsReported = true;
                measurement.UserReportedId = userId;
                measurement.DateReported = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
            else
            {
                var form = await _context.Forms.FindAsync(measurement.FormId.Value);
                if (form == null) throw new ArgumentException("Form not found");

                if (!(form.IsSubmitted && form.IsValidated && !form.IsCancelled))
                {
                    throw new InvalidOperationException("The form is not submitted, validated, or is cancelled.");
                }

                var nonParamTestExists = await _context.MeasurementParams
                    .Include(mp => mp.Test)
                    .AnyAsync(mp => mp.MeasurementId == id && mp.FormId == measurement.FormId.Value && !mp.Test.IsParam);

                if (!nonParamTestExists)
                {
                    throw new InvalidOperationException("Cannot report: No non-parameter test found for this measurement and form.");
                }

                // Check for invalid condition values
                var invalidConditionExists = await _context.MeasurementParams
                    .Where(mp => mp.MeasurementId == id && mp.ConditionValue == 0)
                    .AnyAsync();
                
                if (invalidConditionExists)
                {
                    throw new InvalidOperationException("Cannot report data: one or more form parameters have an invalid condition value (0).");
                }

                measurement.IsReported = true;
                measurement.UserReportedId = userId;
                measurement.DateReported = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }

            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // POST /measurements/{id}/tests
    public async Task<IdDto> AddMeasurementTest(long id, AddMeasurementTestDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var testInfo = await _context.Tests.FindAsync(dto.TestId);
            var isArray = testInfo?.IsArray ?? false;

            // Remove existing tests for this measurement and test ID to avoid conflicts
            var existingTests = await _context.MeasurementTests
                .Where(mt => mt.MeasurementId == id && mt.TestId == dto.TestId)
                .ToListAsync();
            _context.MeasurementTests.RemoveRange(existingTests);

            if (isArray && dto.Value != null)
            {
                var values = new List<decimal>();
                if (dto.Value is JsonElement je && je.ValueKind == JsonValueKind.Array)
                {
                    foreach (var item in je.EnumerateArray())
                    {
                        if (item.TryGetDecimal(out decimal val)) values.Add(val);
                        else if (decimal.TryParse(item.GetString(), out decimal vals)) values.Add(vals);
                    }
                }
                else if (dto.Value is IEnumerable<decimal> doubleEnum) values.AddRange(doubleEnum);
                else if (dto.Value is string s)
                {
                    values = s.Split(',').Select(v => decimal.TryParse(v.Trim(), out decimal val) ? val : 0.0m).ToList();
                }

                for (int i = 0; i < values.Count; i++)
                {
                    _context.MeasurementTests.Add(new MeasurementTest
                    {
                        MeasurementId = id,
                        TestId = dto.TestId,
                        Idx = i,
                        Value = values[i],
                        Note = dto.Note
                    });
                }
            }
            else if (dto.Value != null)
            {
                decimal val = 0;
                if (dto.Value is JsonElement je && je.ValueKind == JsonValueKind.Number) val = je.GetDecimal();
                else if (dto.Value is JsonElement jes && jes.ValueKind == JsonValueKind.String) decimal.TryParse(jes.GetString(), out val);
                else if (decimal.TryParse(dto.Value.ToString(), out decimal parsedVal)) val = parsedVal;

                _context.MeasurementTests.Add(new MeasurementTest
                {
                    MeasurementId = id,
                    TestId = dto.TestId,
                    Idx = 0,
                    Value = val,
                    Note = dto.Note
                });
            }

            await _context.SaveChangesAsync();

            var meas = await _context.Measurements.FindAsync(id);
            if (meas != null && meas.UseDefaultEquipment)
            {
                await RecalculateMeasurementEquipments(id);
            }

            await RecalculateMeasurementSopVersions(id);
            await RecalculateMeasurementReagentLots(id);

            await transaction.CommitAsync();

            return new() { Id = dto.TestId };
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    private async Task RecalculateMeasurementEquipments(long measurementId)
    {
        var measurement = await _context.Measurements
            .Include(m => m.Equipment)
            .Include(m => m.Reception)
            .FirstOrDefaultAsync(m => m.Id == measurementId);

        if (measurement == null) return;

        if (measurement.UseDefaultEquipment)
        {
            // Step 1: get the updated list of test id's for the measurement and with this get a list of unique equipment id's from database table 'test_equipments'.
            var measurementTestIds = new List<long>();
            if (measurement.FormId.HasValue)
            {
                measurementTestIds = await _context.MeasurementParams
                    .Where(mp => mp.MeasurementId == measurementId)
                    .Select(mp => mp.TestId)
                    .Distinct()
                    .ToListAsync();
            }
            else
            {
                measurementTestIds = await _context.MeasurementTests
                    .Where(mt => mt.MeasurementId == measurementId)
                    .Select(mt => mt.TestId)
                    .Distinct()
                    .ToListAsync();
            }

            var step1EquipmentIds = await _context.Tests
                .Where(t => measurementTestIds.Contains(t.Id))
                .SelectMany(t => t.Equipment)
                .Select(e => e.Id)
                .Distinct()
                .ToListAsync();

            // Step 2: get a list of unique equipment id's from database table 'test_equipments' for all applicable tests for the tested material from database table 'material_tests' when field 'type_id' from database table 'receptions' has value 1 or 2 and from database table 'category_tests' when field 'type_id' from database table 'receptions' has value 3.
            var reception = measurement.Reception;
            var applicableTestIds = new List<long>();

            if (reception != null)
            {
                if (reception.TypeId == 1 || reception.TypeId == 2)
                {
                    long? materialId = null;
                    if (reception.ControlCodeId.HasValue)
                    {
                        var cc = await _context.ControlCodes.FindAsync(reception.ControlCodeId.Value);
                        if (cc != null) materialId = cc.MaterialId;
                    }

                    if (materialId.HasValue)
                    {
                        applicableTestIds = await _context.Materials
                            .Where(m => m.Id == materialId.Value)
                            .SelectMany(m => m.Tests)
                            .Select(t => t.Id)
                            .Distinct()
                            .ToListAsync();
                    }
                }
                else if (reception.TypeId == 3)
                {
                    long? categoryId = reception.CategoryId;
                    if (categoryId.HasValue)
                    {
                        applicableTestIds = await _context.Categories
                            .Where(c => c.Id == categoryId.Value)
                            .SelectMany(c => c.Tests)
                            .Select(t => t.Id)
                            .Distinct()
                            .ToListAsync();
                    }
                }
            }

            var step2EquipmentIds = await _context.Tests
                .Where(t => applicableTestIds.Contains(t.Id))
                .SelectMany(t => t.Equipment)
                .Select(e => e.Id)
                .Distinct()
                .ToListAsync();

            // Step 3: get the corresponding list of equipment id's from database table 'measurement_equipments' for the current measurement.
            var step3EquipmentIds = measurement.Equipment.Select(e => e.Id).ToList();

            // Step 4: from the equipment list resulted from (step 3) remove all equipment id�s that are present in list resulted on (step 2)
            var step4EquipmentIds = step3EquipmentIds.Except(step2EquipmentIds).ToList();

            // Step 5: to the equipment list resulted on (step 4) add the equipment list resulted on (step 1) and the resulted list has to be saved in database table 'measurement_equipments'
            var finalEquipmentIds = step4EquipmentIds.Union(step1EquipmentIds).Distinct().ToList();

            measurement.Equipment.Clear();
            if (finalEquipmentIds.Count > 0)
            {
                var equipmentsToAdd = await _context.Equipments.Where(e => finalEquipmentIds.Contains(e.Id)).ToListAsync();
                foreach (var eq in equipmentsToAdd)
                {
                    measurement.Equipment.Add(eq);
                }
            }

            await _context.SaveChangesAsync();
        }
    }
    
    public async Task<List<TestEquipmentDto>> GetMeasurementEquipments(long id)
    {
        var equipments = await _context.Measurements
            .Where(m => m.Id == id)
            .SelectMany(m => m.Equipment)
            .Select(e => new TestEquipmentDto
            {
                Id = e.Id,
                EquipmentCode = e.EquipmentCode,
                Name = e.Name,
                SerialNumber = e.SerialNumber,
                Status = e.Status != null ? e.Status.Name : string.Empty
            })
            .ToListAsync();

        return equipments;
    }

    public async Task<List<MeasurementSopVersionDto>> GetMeasurementSopVersions(long id)
    {
        var sops = await _context.Measurements
            .Where(m => m.Id == id)
            .SelectMany(m => m.SopVersions)
            .Include(sv => sv.Sop)
            .Select(sv => new MeasurementSopVersionDto
            {
                Id = sv.Id,
                SopId = sv.SopId,
                DocCode = sv.Sop.DocCode,
                Title = sv.Sop.Title,
                VersionNumber = sv.VersionNumber,
                ExternalEdmsId = sv.ExternalEdmsId,
                IsActive = sv.IsActive,
                DateActivated = sv.DateActivated,
                Comments = sv.Comments
            })
            .ToListAsync();

        return sops;
    }

    public async Task<List<MeasurementReagentLotDto>> GetMeasurementReagentLots(long id)
    {
        var reagentLots = await _context.Measurements
            .Where(m => m.Id == id)
            .SelectMany(m => m.ControlCodes)
            .Include(rl => rl.ControlCode)
            .ThenInclude(cc => cc.Material)
            .Include(rl => rl.Status)
            .Include(rl => rl.Unit)
            .Select(rl => new MeasurementReagentLotDto
            {
                ControlCodeId = rl.ControlCodeId,
                ControlCode = rl.ControlCode.Code,
                MaterialId = rl.ControlCode.MaterialId,
                MaterialName = rl.ControlCode.Material != null ? rl.ControlCode.Material.Name : string.Empty,
                IsProduced = rl.IsProduced,
                StatusName = rl.Status != null ? rl.Status.Name : string.Empty,
                Quantity = rl.Quantity,
                UnitName = rl.Unit != null ? rl.Unit.Name : null,
                ExpirationDate = rl.ExpirationDate
            })
            .ToListAsync();

        return reagentLots;
    }

    public async Task<List<MeasurementApplicableReagentLotDto>> GetMeasurementApplicableReagentLots(long id)
    {
        var measurement = await _context.Measurements
            .Include(m => m.ControlCodes)
            .FirstOrDefaultAsync(m => m.Id == id);
        if (measurement == null) return new List<MeasurementApplicableReagentLotDto>();

        // Step 1: for the tests present in database table 'measurement_tests' (and measurement_params if form) for the current measurement ('measurement_id') get a list of all unique reagents from database table 'test_reagents'.
        var measurementTestIds = new List<long>();
        if (measurement.FormId.HasValue)
        {
            measurementTestIds = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == id)
                .Select(mp => mp.TestId)
                .Distinct()
                .ToListAsync();
        }
        else
        {
            measurementTestIds = await _context.MeasurementTests
                .Where(mt => mt.MeasurementId == id)
                .Select(mt => mt.TestId)
                .Distinct()
                .ToListAsync();
        }

        // Get unique reagent material ids where is_reagent = true via test_reagents (Tests.MaterialsNavigation)
        var reagentMaterials = await _context.Tests
            .Where(t => measurementTestIds.Contains(t.Id))
            .SelectMany(t => t.MaterialsNavigation)
            .Where(m => m.IsReagent)
            .Distinct()
            .ToListAsync();

        var selectedControlCodeIds = measurement.ControlCodes.Select(cc => cc.ControlCodeId).ToHashSet();

        var result = new List<MeasurementApplicableReagentLotDto>();

        foreach (var reagent in reagentMaterials)
        {
            // Step 2: for each reagent create a list of lots (field 'control_code_id') from database table 'reagent_lots', where field 'status_id' = 1 or 'control_code_id' is present in database table 'measurement_reagent_lots' for the current measurement ('measurement_id').
            var lots = await _context.ReagentLots
                .Include(rl => rl.ControlCode)
                .Where(rl => rl.ControlCode.MaterialId == reagent.Id && (rl.StatusId == 2 || selectedControlCodeIds.Contains(rl.ControlCodeId)))
                .OrderByDescending(rl => rl.ExpirationDate)
                .ToListAsync();

            var lotOptions = lots.Select(rl => new MeasurementReagentLotOptionDto
            {
                ControlCodeId = rl.ControlCodeId,
                ControlCode = rl.ControlCode.Code,
                StatusId = rl.StatusId,
                ExpirationDate = rl.ExpirationDate,
                IsSelected = selectedControlCodeIds.Contains(rl.ControlCodeId)
            }).ToList();

            result.Add(new MeasurementApplicableReagentLotDto
            {
                MaterialId = reagent.Id,
                MaterialName = reagent.Name,
                Lots = lotOptions
            });
        }

        return result;
    }

    public async Task UpdateMeasurementReagentLots(long id, UpdateMeasurementReagentLotsDto dto)
    {
        var measurement = await _context.Measurements.Include(m => m.ControlCodes).FirstOrDefaultAsync(m => m.Id == id);
        if (measurement == null) throw new ArgumentException("Measurement not found");

        measurement.ControlCodes.Clear();

        if (dto.ControlCodeIds != null && dto.ControlCodeIds.Count > 0)
        {
            var lots = await _context.ReagentLots.Where(rl => dto.ControlCodeIds.Contains(rl.ControlCodeId)).ToListAsync();
            foreach (var lot in lots) measurement.ControlCodes.Add(lot);
        }

        await _context.SaveChangesAsync();
    }

    public async Task<List<MeasurementSopVersionDto>> GetMeasurementApplicableSopVersions(long id)
    {
        var measurement = await _context.Measurements.FindAsync(id);
        if (measurement == null) return new List<MeasurementSopVersionDto>();

        var measurementTestIds = new List<long>();
        if (measurement.FormId.HasValue)
        {
            measurementTestIds = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == id)
                .Select(mp => mp.TestId)
                .Distinct()
                .ToListAsync();
        }
        else
        {
            measurementTestIds = await _context.MeasurementTests
                .Where(mt => mt.MeasurementId == id)
                .Select(mt => mt.TestId)
                .Distinct()
                .ToListAsync();
        }

        var uniqueSopIds = await _context.Tests
            .Where(t => measurementTestIds.Contains(t.Id) && t.SopId.HasValue)
            .Select(t => t.SopId!.Value)
            .Distinct()
            .ToListAsync();

        var activeSopVersions = await _context.SopVersions
            .Where(sv => uniqueSopIds.Contains(sv.SopId))
            .Include(sv => sv.Sop)
            .Select(sv => new MeasurementSopVersionDto
            {
                Id = sv.Id,
                SopId = sv.SopId,
                DocCode = sv.Sop.DocCode,
                Title = sv.Sop.Title,
                VersionNumber = sv.VersionNumber,
                ExternalEdmsId = sv.ExternalEdmsId,
                IsActive = sv.IsActive,
                DateActivated = sv.DateActivated,
                Comments = sv.Comments
            })
            .ToListAsync();

        return activeSopVersions;
    }

    public async Task UpdateMeasurementEquipments(long id, UpdateTestEquipmentsDto dto)
    {
        var measurement = await _context.Measurements.Include(m => m.Equipment).FirstOrDefaultAsync(m => m.Id == id);
        if (measurement == null) throw new ArgumentException("Measurement not found");

        measurement.Equipment.Clear();

        if (dto.EquipmentIds != null && dto.EquipmentIds.Count > 0)
        {
            var equipments = await _context.Equipments.Where(e => dto.EquipmentIds.Contains(e.Id)).ToListAsync();
            foreach (var eq in equipments) measurement.Equipment.Add(eq);
        }

        await _context.SaveChangesAsync();
    }

    public async Task UpdateMeasurementSopVersions(long id, UpdateMeasurementSopVersionsDto dto)
    {
        var measurement = await _context.Measurements.Include(m => m.SopVersions).FirstOrDefaultAsync(m => m.Id == id);
        if (measurement == null) throw new ArgumentException("Measurement not found");

        measurement.SopVersions.Clear();

        if (dto.SopVersionIds != null && dto.SopVersionIds.Count > 0)
        {
            var sopVersions = await _context.SopVersions.Where(sv => dto.SopVersionIds.Contains(sv.Id)).ToListAsync();
            foreach (var sv in sopVersions) measurement.SopVersions.Add(sv);
        }

        await _context.SaveChangesAsync();
    }

    // POST/PUT /measurements/{id}/form_data (Internal helper now)
    private async Task SaveMeasurementFormData(long id, Dictionary<string, object?> data)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            await SaveMeasurementFormDataInternal(id, data);
            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    private async Task SaveMeasurementFormDataInternal(long id, Dictionary<string, object?> data)
    {
        var measurement = await _context.Measurements.FindAsync(id);
        if (measurement == null || !measurement.FormId.HasValue)
        {
            throw new ArgumentException("Form not associated with this measurement");
        }
        var formId = measurement.FormId.Value;

        // Ensure is_reported is set to false, UserReportedId is cleared, and DateReported is cleared when saving measurement params
        measurement.IsReported = false;
        measurement.UserReportedId = null;
        measurement.DateReported = null;
        await _context.SaveChangesAsync();

        var formParamsSchema = await _formsService.GetFormParams(formId);

        // 1. Prepare measurementData (Inputs)
        var inputParams = formParamsSchema.Where(p => !p.IsCalculated).ToList();
        var flatInputs = FormEvalMapper.MapDictToFlat(data, inputParams);
        var measurementData = FormEvalMapper.MapFlatToDict(flatInputs, inputParams);

        // 2. Call EvaluateFormCalculations from FormsService
        Dictionary<string, object> results;
        try
        {
            results = await _formsService.EvaluateFormCalculations(formId, measurementData!);
        }
        catch (Exception ex)
        {
             throw new Exception($"Evaluation error: {ex.Message}", ex);
        }

        // 3. Update database with results
        var flatResults = FormEvalMapper.MapDictToFlat(results!, formParamsSchema.Where(p => p.IsCalculated).ToList());

        // Clear all existing params first
        var allParams = await _context.MeasurementParams.Where(mp => mp.MeasurementId == id).ToListAsync();
        _context.MeasurementParams.RemoveRange(allParams);
        await _context.SaveChangesAsync();

        // Save Inputs
        foreach (var item in flatInputs)
        {
            var param = new MeasurementParam
            {
                MeasurementId = id,
                FormId = formId,
                TestId = item.TestId,
                Idx = item.Idx,
                Value = item.Value
            };

            var formParam = formParamsSchema.FirstOrDefault(p => p.TestId == item.TestId);
            if (formParam != null && formParam.HasCondition && !string.IsNullOrEmpty(formParam.Condition))
            {
                param.ConditionValue = QCLab.Utils.FormulaUtils.CalculateConditionValue(formParam.Condition, item.Value);
            }

            _context.MeasurementParams.Add(param);
        }

        // Save Results
        foreach (var item in flatResults)
        {
            var param = new MeasurementParam
            {
                MeasurementId = id,
                FormId = formId,
                TestId = item.TestId,
                Idx = item.Idx,
                Value = item.Value
            };

            var formParam = formParamsSchema.FirstOrDefault(p => p.TestId == item.TestId);
            if (formParam != null && formParam.HasCondition && !string.IsNullOrEmpty(formParam.Condition))
            {
                param.ConditionValue = QCLab.Utils.FormulaUtils.CalculateConditionValue(formParam.Condition, item.Value);
            }

            _context.MeasurementParams.Add(param);
        }

        await _context.SaveChangesAsync();
    }

    private async Task RecalculateMeasurementSopVersions(long measurementId)
    {
        var measurement = await _context.Measurements
            .Include(m => m.SopVersions)
            .FirstOrDefaultAsync(m => m.Id == measurementId);

        if (measurement == null) return;

        // Step 1: get the updated list of test id's, and with this, get a list of unique SOP id's from database table 'tests', but with the corresponding active SOP version id. If there is no active SOP version, that SOP id will be ignored. Result [(sop_id, sop_version_id)]
        var measurementTestIds = new List<long>();
        if (measurement.FormId.HasValue)
        {
            measurementTestIds = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == measurementId)
                .Select(mp => mp.TestId)
                .Distinct()
                .ToListAsync();
        }
        else
        {
            measurementTestIds = await _context.MeasurementTests
                .Where(mt => mt.MeasurementId == measurementId)
                .Select(mt => mt.TestId)
                .Distinct()
                .ToListAsync();
        }

        var testsWithSops = await _context.Tests
            .Where(t => measurementTestIds.Contains(t.Id) && t.SopId.HasValue)
            .Select(t => new { TestId = t.Id, SopId = t.SopId!.Value })
            .ToListAsync();

        var uniqueSopIds = testsWithSops.Select(ts => ts.SopId).Distinct().ToList();

        var activeSopVersions = await _context.SopVersions
            .Where(sv => uniqueSopIds.Contains(sv.SopId) && sv.IsActive)
            .Select(sv => new { sv.SopId, SopVersionId = sv.Id })
            .ToListAsync();

        var step1Pairs = activeSopVersions
            .Select(sv => new { sv.SopId, sv.SopVersionId })
            .ToList();

        // Step 2: get the corresponding list of sop version id’s from database table 'measurement_sop_versions' for the current measurement but with the corresponding SOP id’s. Result [(sop_id, sop_version_id)]
        var measurementSopVersionsList = await _context.Measurements
            .Where(m => m.Id == measurementId)
            .SelectMany(m => m.SopVersions)
            .Select(sv => new { sv.SopId, SopVersionId = sv.Id })
            .ToListAsync();

        var step2Pairs = measurementSopVersionsList;

        // Step 3: from the SOPs list resulted from (step 2) remove all items where sop_id is not present in list resulted on (step 1)
        var step1SopIds = step1Pairs.Select(p => p.SopId).ToHashSet();
        var step3Pairs = step2Pairs.Where(p => step1SopIds.Contains(p.SopId)).ToList();

        // Step 4: from the SOP list resulted on (step 1) remove all the items where sop_id is not present in list resulted on (step 3)
        var step3SopIds = step3Pairs.Select(p => p.SopId).ToHashSet();
        var step4Pairs = step1Pairs.Where(p => !step3SopIds.Contains(p.SopId)).ToList();

        // Step 5: to the SOP list resulted on (step 3) add the SOP list resulted on (step 4) and the resulted list has to be saved in database table 'measurement_sop_versions' (just the sop_version_id with the corresponding measurement_id) by completely replacing the previous values present for the current 'measurement_id'.
        var finalSopVersionIds = step3Pairs.Select(p => p.SopVersionId)
            .Union(step4Pairs.Select(p => p.SopVersionId))
            .Distinct()
            .ToList();

        measurement.SopVersions.Clear();
        if (finalSopVersionIds.Count > 0)
        {
            var sopVersionsToAdd = await _context.SopVersions
                .Where(sv => finalSopVersionIds.Contains(sv.Id))
                .ToListAsync();

            foreach (var sv in sopVersionsToAdd)
            {
                measurement.SopVersions.Add(sv);
            }
        }

        await _context.SaveChangesAsync();
    }

    private async Task RecalculateMeasurementReagentLots(long measurementId)
    {
        var measurement = await _context.Measurements
            .Include(m => m.ControlCodes)
            .ThenInclude(cc => cc.ControlCode)
            .FirstOrDefaultAsync(m => m.Id == measurementId);

        if (measurement == null) return;

        // Step 1: get the updated list of test id's, and with this, get a list of unique reagent id's from database table 'test_reagents'. Result [material_id, ...] (a list of integers)
        var measurementTestIds = new List<long>();
        if (measurement.FormId.HasValue)
        {
            measurementTestIds = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == measurementId)
                .Select(mp => mp.TestId)
                .Distinct()
                .ToListAsync();
        }
        else
        {
            measurementTestIds = await _context.MeasurementTests
                .Where(mt => mt.MeasurementId == measurementId)
                .Select(mt => mt.TestId)
                .Distinct()
                .ToListAsync();
        }

        var materialIds = await _context.Tests
            .Where(t => measurementTestIds.Contains(t.Id))
            .SelectMany(t => t.MaterialsNavigation)
            .Select(m => m.Id)
            .Distinct()
            .ToListAsync();

        // Step 2: for each material (reagent) in the list resulted at (step 1) find all the active lots (field 'status_id' = 1) in database table 'reagent_lots' that did not expired. 
        // If the list is not empty select the lot (field 'control_code_id') with the closest expiration date (consume the oldest first), 
        // but if the list is empty search for expired active lots and if the list is not empty return the lot that expired most recently. 
        // If the expired active list is empty, ignore the respective material (will not be part of the result). Result [(material_id, control_code_id), ...] (a list of pairs)
        var today = DateOnly.FromDateTime(DateTime.Today);
        var step2Pairs = new List<(long MaterialId, long ControlCodeId)>();

        foreach (var materialId in materialIds)
        {
            var reagentLots = await _context.ReagentLots
                .Include(rl => rl.ControlCode)
                .Where(rl => rl.ControlCode.MaterialId == materialId && rl.StatusId == 2)
                .ToListAsync();

            var unexpiredLots = reagentLots
                .Where(rl => rl.ExpirationDate >= today)
                .OrderBy(rl => rl.ExpirationDate)
                .ToList();

            if (unexpiredLots.Count > 0)
            {
                step2Pairs.Add((materialId, unexpiredLots.First().ControlCodeId));
            }
            else
            {
                var expiredLots = reagentLots
                    .Where(rl => rl.ExpirationDate < today)
                    .OrderByDescending(rl => rl.ExpirationDate)
                    .ToList();

                if (expiredLots.Count > 0)
                {
                    step2Pairs.Add((materialId, expiredLots.First().ControlCodeId));
                }
            }
        }

        // Step 3: get the corresponding list of reagent lot id’s ('control_code_id') from database table 'measurement_reagent_lots' for the current measurement, but with the corresponding reagent id’s ('material_id'). Result [(material_id, control_code_id), ...]
        var step3Pairs = measurement.ControlCodes
            .Select(cc => (MaterialId: cc.ControlCode.MaterialId, ControlCodeId: cc.ControlCodeId))
            .ToList();

        // Step 4: from the reagent lots list resulted from (step 3) remove all items where material_id is not present in list resulted on (step 1)
        var step1MaterialIdsHashSet = materialIds.ToHashSet();
        var step4Pairs = step3Pairs
            .Where(p => step1MaterialIdsHashSet.Contains(p.MaterialId))
            .ToList();

        // Step 5: from the reagent lots list resulted on (step 2) remove all the items where material_id is present in list resulted on (step 4)
        var step4MaterialIdsHashSet = step4Pairs.Select(p => p.MaterialId).ToHashSet();
        var step5Pairs = step2Pairs
            .Where(p => !step4MaterialIdsHashSet.Contains(p.MaterialId))
            .ToList();

        // Step 6: to the reagent lots list resulted on (step 4) add the reagent lots list resulted on (step 5) and the resulted list has to be saved in database table 'measurement_reagent_lots' (just the control_code_id with the corresponding measurement_id) by completely replacing the previous values present for the current 'measurement_id'.
        var finalControlCodeIds = step4Pairs.Select(p => p.ControlCodeId)
            .Union(step5Pairs.Select(p => p.ControlCodeId))
            .Distinct()
            .ToList();

        measurement.ControlCodes.Clear();
        if (finalControlCodeIds.Count > 0)
        {
            var lotsToAdd = await _context.ReagentLots
                .Where(rl => finalControlCodeIds.Contains(rl.ControlCodeId))
                .ToListAsync();

            foreach (var lot in lotsToAdd)
            {
                measurement.ControlCodes.Add(lot);
            }
        }

        await _context.SaveChangesAsync();
    }
}
