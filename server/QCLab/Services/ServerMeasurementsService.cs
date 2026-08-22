using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using System.Text.Json;
using System.Globalization;
using QCLab.Utils;
using QCFormula;

namespace QCLab.Services;

public class ServerMeasurementsService : IMeasurementsService
{
    private readonly QualityControlContext _context;
    private readonly IFormsService _formsService;

    public ServerMeasurementsService(QualityControlContext context, IFormsService formsService)
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
    public async Task<IdDto> CreateMeasurement(CreateMeasurementDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = new Measurement
            {
                ReceptionId = dto.ReceptionId,
                Comments = dto.Comments,
                IsReported = dto.IsReported,
                FormId = dto.FormId,
                UserUpdateId = dto.UserUpdateId,
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
    public async Task UpdateMeasurementTest(long id, UpdateMeasurementTestBulkDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement == null) throw new ArgumentException("Measurement not found");

            measurement.Comments = dto.Comments;
            measurement.IsReported = false;
            measurement.UserReportedId = null;
            measurement.UserUpdateId = dto.UserUpdateId;
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

            await transaction.CommitAsync();
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    public async Task UpdateMeasurementParam(long id, UpdateMeasurementParamDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var measurement = await _context.Measurements.FindAsync(id);
            if (measurement == null) throw new ArgumentException("Measurement not found");

            measurement.Comments = dto.Comments;
            measurement.IsReported = dto.IsReported;
            measurement.UserUpdateId = dto.UserUpdateId;
            measurement.DateUpdate = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            await SaveMeasurementFormDataInternal(id, dto.MeasurementData);
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
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                return;
            }

            if (!measurement.FormId.HasValue)
            {
                measurement.IsReported = true;
                measurement.UserReportedId = userId;
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
            await transaction.CommitAsync();

            return new() { Id = dto.TestId };
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
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

        // Ensure is_reported is set to false and UserReportedId is cleared when saving measurement params
        measurement.IsReported = false;
        measurement.UserReportedId = null;
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
}
