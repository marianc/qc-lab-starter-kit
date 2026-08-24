using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCFormula;
using QCLab.Utils;

namespace QCLab.Services;

public class ServerReceptionsService : IReceptionsService
{
    private readonly QualityControlContext _context;
    private readonly IFormsService _formsService;
    private readonly ICertificatesService _certificatesService;
    private readonly ElectronicSignatureService _signatureService;

    public ServerReceptionsService(QualityControlContext context, IFormsService formsService, ICertificatesService certificatesService, ElectronicSignatureService signatureService)
    {
        _context = context;
        _formsService = formsService;
        _certificatesService = certificatesService;
        _signatureService = signatureService;
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

            var measurementParamsRows = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == measurementId && mp.FormId == formId)
                .ToListAsync();

            var flatParams = measurementParamsRows.Select(mp => new MeasurementFlatData { 
                TestId = mp.TestId, 
                Idx = mp.Idx, 
                Value = mp.Value,
                ConditionValue = mp.ConditionValue
            }).ToList();
            var allDataDict = FormEvalMapper.MapFlatToDict(flatParams, formParamsSchema);
            var allConditionDict = FormEvalMapper.MapConditionToDict(flatParams, formParamsSchema);

            foreach (var param in formParamsSchema)
            {
                object? value = allDataDict.TryGetValue(param.Code, out var val) ? val : null;
                if (value == null && !param.IsCalculated) value = param.DefaultValue;

                if (param.IsCalculated) dto.CalculatedResults[param.Code] = value;
                else dto.MeasurementData[param.Code] = value;

                if (param.HasCondition && !string.IsNullOrEmpty(param.Condition))
                {
                    object? condVal = allConditionDict.TryGetValue(param.Code, out var cval) ? cval : null;
                    if (condVal != null)
                    {
                        if (condVal is System.Collections.IEnumerable list && !(condVal is string))
                        {
                            var passList = new List<bool?>();
                            foreach (var item in list)
                            {
                                if (item == null) passList.Add(null);
                                else if (item is bool b) passList.Add(b);
                                else if (decimal.TryParse(item.ToString(), out decimal dec)) passList.Add(dec != 0);
                                else passList.Add(null);
                            }
                            dto.ConditionPass[param.Code] = passList;
                        }
                        else
                        {
                            if (condVal is bool b) dto.ConditionPass[param.Code] = b;
                            else if (decimal.TryParse(condVal.ToString(), out decimal dec)) dto.ConditionPass[param.Code] = (dec != 0);
                            else dto.ConditionPass[param.Code] = null;
                        }
                    }
                    else
                    {
                        dto.ConditionPass[param.Code] = null;
                    }
                }
            }

            return dto;
        }
        return null;
    }

    // GET /receptions/:reception_id/applicable_forms
    public async Task<List<ApplicableFormDto>> GetApplicableForms(long reception_id)
    {
        var reception = await _context.Receptions.FindAsync(reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");

        var applicableTestIds = new HashSet<long>();

        if (reception.TypeId == 1 || reception.TypeId == 2)
        {
            if (reception.ControlCodeId.HasValue)
            {
                var controlCode = await _context.ControlCodes.FindAsync(reception.ControlCodeId.Value);
                if (controlCode != null)
                {
                    var materialTests = await _context.Materials
                        .Where(m => m.Id == controlCode.MaterialId)
                        .SelectMany(m => m.Tests)
                        .Select(t => t.Id)
                        .ToListAsync();
                    foreach (var tid in materialTests) applicableTestIds.Add(tid);
                }
            }
        }
        else if (reception.TypeId == 3)
        {
            if (reception.CategoryId.HasValue)
            {
                var categoryTests = await _context.Categories
                    .Where(c => c.Id == reception.CategoryId.Value)
                    .SelectMany(c => c.Tests)
                    .Select(t => t.Id)
                    .ToListAsync();
                foreach (var tid in categoryTests) applicableTestIds.Add(tid);
            }
        }

        var allForms = await _context.Forms
            .Include(f => f.FormGroup)
            .Where(f => !f.IsCancelled && f.IsSubmitted)
            .ToListAsync();

        var applicableForms = new List<ApplicableFormDto>();

        foreach (var form in allForms)
        {
            var formTestIds = await _context.FormParams
                .Where(fp => fp.FormId == form.Id && !fp.Test.IsParam)
                .Select(fp => fp.TestId)
                .ToListAsync();

            if (formTestIds.All(tid => applicableTestIds.Contains(tid)))
            {
                applicableForms.Add(new ApplicableFormDto
                {
                    Id = form.Id,
                    Name = $"{form.FormGroup.Name} ({form.Version})",
                    IsCustomized = form.IsCustomized,
                    CustomNav = form.CustomNav,
                    IsCancelled = form.IsCancelled,
                    IsSubmitted = form.IsSubmitted,
                    IsValidated = form.IsValidated
                });
            }
        }

        return applicableForms;
    }

    // GET /receptions
    public async Task<PaginatedReceptionsDto> GetAllReceptions(
        int page,
        int per_page,
        long? user_id,
        long? submitted_by,
        long? type_id,
        long? material_id,
        string? report_submitted,
        string? status,
        int? submission_year,
        int? submission_month)
    {
        var query = _context.Receptions
            .Include(r => r.Type)
            .Include(r => r.ControlCode)
                .ThenInclude(cc => cc.Material)
            .Include(r => r.Category)
            .Include(r => r.UserSubmitted)
            .Include(r => r.UserReceived)
            .Include(r => r.UserRejected)
            .Include(r => r.Reports)
            .AsQueryable();

        if (user_id.HasValue)
        {
            var user = await _context.Users.FindAsync(user_id.Value);
            bool isLabPers = user != null && user.IsLabPers;

            if (isLabPers)
            {
                query = query.Where(r => r.UserSubmittedId == user_id || r.UserReceivedId == user_id || r.UserRejectedId == user_id || r.IsSubmitted);
            }
            else
            {
                query = query.Where(r => r.UserSubmittedId == user_id || r.UserReceivedId == user_id || r.UserRejectedId == user_id);
            }
        }

        if (submitted_by.HasValue)
        {
            query = query.Where(r => r.UserSubmittedId == submitted_by);
        }

        if (type_id.HasValue)
        {
            query = query.Where(r => r.TypeId == type_id);
        }

        if (material_id.HasValue)
        {
            query = query.Where(r => r.ControlCode != null && r.ControlCode.MaterialId == material_id);
        }

        if (report_submitted == "true")
        {
            query = query.Where(r => r.Reports.Any(rep => !rep.IsCancelled));
        }
        else if (report_submitted == "false")
        {
            query = query.Where(r => !r.Reports.Any(rep => !rep.IsCancelled));
        }

        if (!string.IsNullOrEmpty(status))
        {
            if (status == "Pending")
            {
                query = query.Where(r => !r.IsSubmitted && !r.IsReceived && !r.IsRejected);
            }
            else if (status == "Submitted")
            {
                query = query.Where(r => r.IsSubmitted && !r.IsReceived && !r.IsRejected);
            }
            else if (status == "Received")
            {
                query = query.Where(r => r.IsReceived);
            }
            else if (status == "Rejected")
            {
                query = query.Where(r => r.IsRejected);
            }
        }

        if (submission_year.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Year == submission_year.Value);
        }

        if (submission_month.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Month == submission_month.Value);
        }

        var totalRecords = await query.CountAsync();
        var totalPages = (long)Math.Ceiling((double)totalRecords / per_page);

        var receptions = await query
            .OrderByDescending(r => r.Id)
            .Skip((page - 1) * per_page)
            .Take(per_page)
            .ToListAsync();

        var formattedReceptions = receptions.Select(r =>
        {
            string? materialName = r.MaterialName;
            if ((r.TypeId == 1 || r.TypeId == 2) && r.ControlCode != null && r.ControlCode.Material != null)
            {
                materialName = r.ControlCode.Material.Name;
            }

            string statusStr = "Pending";
            if (r.IsRejected) statusStr = "Rejected";
            else if (r.IsReceived) statusStr = "Received";
            else if (r.IsSubmitted) statusStr = "Submitted";

            return new ReceptionDto
            {
                Id = r.Id,
                TypeId = r.TypeId,
                ReceptionTypeName = r.Type.Name,
                ControlCodeId = r.ControlCodeId,
                MaterialName = materialName,
                ControlCodeName = r.ControlCode?.Code,
                CommentsSubmitted = r.CommentsSubmitted,
                CategoryId = r.CategoryId,
                CategoryName = r.Category?.Name,
                IsSubmitted = r.IsSubmitted,
                UserSubmittedId = r.UserSubmittedId,
                UserSubmittedTag = r.UserSubmitted?.Tag,
                DateSubmitted = r.DateSubmitted,
                IsReceived = r.IsReceived,
                UserReceivedId = r.UserReceivedId,
                UserReceivedTag = r.UserReceived?.Tag,
                DateReceived = r.DateReceived,
                CommentsReceived = r.CommentsReceived,
                IsRejected = r.IsRejected,
                UserRejectedId = r.UserRejectedId,
                UserRejectedTag = r.UserRejected?.Tag,
                DateRejected = r.DateRejected,
                CommentsRejected = r.CommentsRejected,
                ReportSubmitted = r.Reports.Any(rep => !rep.IsCancelled),
                Status = statusStr
            };
        }).ToList();

        return new PaginatedReceptionsDto
        {
            Receptions = formattedReceptions,
            TotalPages = totalPages,
            CurrentPage = page,
            TotalCount = totalRecords
        };
    }

    // GET /receptions/:reception_id
    public async Task<ReceptionDetailDto?> GetReception(long reception_id)
    {
        var reception = await _context.Receptions
            .Include(r => r.Type)
            .Include(r => r.ControlCode)
                .ThenInclude(cc => cc.Material)
            .Include(r => r.Category)
            .Include(r => r.UserSubmitted)
            .Include(r => r.UserReceived)
            .Include(r => r.UserRejected)
            .Include(r => r.Tests)
            .FirstOrDefaultAsync(r => r.Id == reception_id);

        if (reception == null) return null;

        string? materialName = reception.MaterialName;
        if ((reception.TypeId == 1 || reception.TypeId == 2) && reception.ControlCode != null && reception.ControlCode.Material != null)
        {
            materialName = reception.ControlCode.Material.Name;
        }

        string statusStr = "Pending";
        if (reception.IsRejected) statusStr = "Rejected";
        else if (reception.IsReceived) statusStr = "Received";
        else if (reception.IsSubmitted) statusStr = "Submitted";

        var dto = new ReceptionDetailDto
        {
            Id = reception.Id,
            TypeId = reception.TypeId,
            ReceptionTypeName = reception.Type.Name,
            ControlCodeId = reception.ControlCodeId,
            MaterialId = reception.ControlCode?.Material?.Id,
            MaterialName = materialName,
            ControlCodeName = reception.ControlCode?.Code,
            CommentsSubmitted = reception.CommentsSubmitted,
            CategoryId = reception.CategoryId,
            CategoryName = reception.Category?.Name,
            IsSubmitted = reception.IsSubmitted,
            UserSubmittedId = reception.UserSubmittedId,
            UserSubmittedTag = reception.UserSubmitted?.Tag,
            DateSubmitted = reception.DateSubmitted,
            IsReceived = reception.IsReceived,
            UserReceivedId = reception.UserReceivedId,
            UserReceivedTag = reception.UserReceived?.Tag,
            DateReceived = reception.DateReceived,
            CommentsReceived = reception.CommentsReceived,
            IsRejected = reception.IsRejected,
            UserRejectedId = reception.UserRejectedId,
            UserRejectedTag = reception.UserRejected?.Tag,
            DateRejected = reception.DateRejected,
            CommentsRejected = reception.CommentsRejected,
            Status = statusStr,
            ApplicableForms = new List<long>(),
            ApplicableTests = new List<long>(),
            ReceptionTests = (reception.TypeId == 2 || reception.TypeId == 3) 
                ? reception.Tests.Select(t => t.Id).ToList() 
                : null
        };

        // Calculate applicable tests and forms
        var applicableTestIds = new HashSet<long>();

        if (reception.TypeId == 1 || reception.TypeId == 2)
        {
            if (reception.ControlCodeId.HasValue)
            {
                var controlCode = await _context.ControlCodes.FindAsync(reception.ControlCodeId.Value);
                if (controlCode != null)
                {
                    applicableTestIds = (await _context.Materials
                        .Where(m => m.Id == controlCode.MaterialId)
                        .SelectMany(m => m.Tests)
                        .Select(t => t.Id)
                        .ToListAsync()).ToHashSet();
                }
            }
        }
        else if (reception.TypeId == 3)
        {
            if (reception.CategoryId.HasValue)
            {
                applicableTestIds = (await _context.Categories
                    .Where(c => c.Id == reception.CategoryId.Value)
                    .SelectMany(c => c.Tests)
                    .Select(t => t.Id)
                    .ToListAsync()).ToHashSet();
            }
        }

        dto.ApplicableTests = applicableTestIds.ToList();

        var allForms = await _context.Forms
            .Where(f => !f.IsCancelled && f.IsSubmitted)
            .ToListAsync();

        foreach (var form in allForms)
        {
            var formTestIds = await _context.FormParams
                .Where(fp => fp.FormId == form.Id && !fp.Test.IsParam)
                .Select(fp => fp.TestId)
                .ToListAsync();

            if (formTestIds.All(tid => applicableTestIds.Contains(tid)))
            {
                dto.ApplicableForms.Add(form.Id);
            }
        }

        return dto;
    }

    // POST /receptions
    public async Task<IdDto> CreateReception(CreateReceptionDto dto)
    {
        var reception = new Reception
        {
            TypeId = dto.TypeId,
            ControlCodeId = dto.ControlCodeId,
            CategoryId = dto.CategoryId,
            CommentsSubmitted = dto.CommentsSubmitted,
            MaterialName = dto.MaterialName,
            UserSubmittedId = dto.UserId,
            DateSubmitted = DateTime.UtcNow
        };

        _context.Receptions.Add(reception);
        await _context.SaveChangesAsync();

        return new() { Id = reception.Id };
    }

    // PUT /receptions/:reception_id
    public async Task UpdateReception(long reception_id, UpdateReceptionDto dto)
    {
        var reception = await _context.Receptions.FindAsync(reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");

        reception.TypeId = dto.TypeId;
        reception.ControlCodeId = dto.ControlCodeId;
        reception.CategoryId = dto.CategoryId;
        reception.CommentsSubmitted = dto.CommentsSubmitted;
        reception.MaterialName = dto.MaterialName;

        if (!reception.IsSubmitted)
        {
            reception.UserSubmittedId = dto.UserId;
            reception.DateSubmitted = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    // GET /receptions/:reception_id/tests
    public async Task<List<ReceptionTestDto>> GetReceptionTests(long reception_id)
    {
        var tests = await _context.Receptions
            .Where(r => r.Id == reception_id)
            .SelectMany(r => r.Tests)
            .Where(t => !t.IsParam)
            .Select(t => new ReceptionTestDto
            {
                Id = t.Id,
                Name = t.Name
            })
            .ToListAsync();

        return tests;
    }

    // PUT /receptions/:reception_id/tests
    public async Task UpdateReceptionTests(long reception_id, UpdateReceptionTestsDto dto)
    {
        var reception = await _context.Receptions.Include(r => r.Tests).FirstOrDefaultAsync(r => r.Id == reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");

        // Clear existing
        reception.Tests.Clear();

        // Add new
        if (dto.TestIds != null && dto.TestIds.Count > 0)
        {
            var tests = await _context.Tests.Where(t => dto.TestIds.Contains(t.Id)).ToListAsync();
            foreach (var t in tests) reception.Tests.Add(t);
        }

        await _context.SaveChangesAsync();
    }

    // PUT /receptions/:reception_id/submit
    public async Task SubmitReception(long reception_id, SubmitReceptionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required for submission");

        var reception = await _context.Receptions.FindAsync(reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");
        if (reception.IsSubmitted) throw new InvalidOperationException("Reception already submitted");

        reception.IsSubmitted = true;
        reception.UserSubmittedId = dto.UserId;
        reception.DateSubmitted = DateTime.UtcNow;
        reception.CommentsSubmitted = dto.Comments;

        await _context.SaveChangesAsync();
    }

    public async Task CancelSubmission(long reception_id)
    {
        var reception = await _context.Receptions.FindAsync(reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");
        if (!reception.IsSubmitted) throw new InvalidOperationException("Reception not submitted");
        if (reception.IsReceived || reception.IsRejected) throw new InvalidOperationException("Cannot cancel submission: reception already processed (received or rejected)");

        reception.IsSubmitted = false;
        await _context.SaveChangesAsync();
    }

    // PUT /receptions/:reception_id/receive
    public async Task ReceiveReception(long reception_id, ReceiveReceptionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var reception = await _context.Receptions.FindAsync(reception_id);
            if (reception == null) throw new ArgumentException("Reception not found");
            if (!reception.IsSubmitted) throw new InvalidOperationException("Reception not submitted yet");
            if (reception.IsReceived || reception.IsRejected) throw new InvalidOperationException("Reception already processed (received or rejected)");

            reception.IsReceived = true;
            reception.UserReceivedId = dto.UserId;
            reception.DateReceived = DateTime.UtcNow;
            reception.CommentsReceived = dto.Comments;

            if (reception.ControlCodeId.HasValue)
            {
                var cc = await _context.ControlCodes.FindAsync(reception.ControlCodeId.Value);
                if (cc != null) cc.IsReceptionReceived = true;
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

    // PUT /receptions/:reception_id/reject
    public async Task RejectReception(long reception_id, RejectReceptionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required");
        if (string.IsNullOrEmpty(dto.Reason)) throw new ArgumentException("Reason for rejection is required");

        var reception = await _context.Receptions.FindAsync(reception_id);
        if (reception == null) throw new ArgumentException("Reception not found");
        if (!reception.IsSubmitted) throw new InvalidOperationException("Reception not submitted yet");
        if (reception.IsReceived || reception.IsRejected) throw new InvalidOperationException("Reception already processed (received or rejected)");

        reception.IsRejected = true;
        reception.UserRejectedId = dto.UserId;
        reception.DateRejected = DateTime.UtcNow;
        reception.CommentsRejected = dto.Reason;

        await _context.SaveChangesAsync();
    }

    // GET /receptions/:reception_id/reports
    public async Task<List<ReportSummaryDto>> GetReceptionReports(long reception_id)
    {
        var reports = await _context.Reports
            .Include(r => r.UserSubmitted)
            .Include(r => r.UserCancelled)
            .Where(r => r.ReceptionId == reception_id)
            .OrderByDescending(r => r.Id)
            .Select(r => new ReportSummaryDto
            {
                Id = r.Id,
                DateSubmitted = r.DateSubmitted,
                UserSubmittedTag = r.UserSubmitted != null ? r.UserSubmitted.Tag : null,
                CommentsSubmitted = r.CommentsSubmitted,
                ReportReplacedId = r.ReportReplacedId,
                DateCancelled = r.DateCancelled,
                UserCancelledTag = r.UserCancelled != null ? r.UserCancelled.Tag : null,
                CommentsCancelled = r.CommentsCancelled
            })
            .ToListAsync();

        return reports;
    }

    // POST /receptions/:reception_id/create_report
    public async Task<IdDto> CreateReport(long reception_id, CreateReportDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var existingReport = await _context.Reports.FirstOrDefaultAsync(r => r.ReceptionId == reception_id && !r.IsCancelled);
            long? reportReplacedId = null;

            if (existingReport != null)
            {
                reportReplacedId = existingReport.Id;
                existingReport.IsCancelled = true;
                existingReport.UserCancelledId = dto.UserId;
                existingReport.DateCancelled = DateTime.UtcNow;
                existingReport.CommentsCancelled = $"Replaced by new report for reception {reception_id}";
            }

            var newReport = new Report
            {
                ReceptionId = reception_id,
                IsSubmitted = true,
                UserSubmittedId = dto.UserId,
                DateSubmitted = DateTime.UtcNow,
                CommentsSubmitted = dto.Comments,
                ReportReplacedId = reportReplacedId,
                IsCancelled = false
            };

            _context.Reports.Add(newReport);
            await _context.SaveChangesAsync();

            if (existingReport != null)
            {
                existingReport.CommentsCancelled = $"Replaced by new report #{newReport.Id}";
                await _context.SaveChangesAsync();

                await _signatureService.SignEntityAsync(
                    "reports",
                    existingReport.Id,
                    dto.UserId,
                    "Cancellation",
                    "127.0.0.1",
                    existingReport.CommentsCancelled,
                    _context);
            }

            var reportTestData = await GetReportTestDataInternal(reception_id);

            if (reportTestData.Count == 0)
            {
                throw new InvalidOperationException("No reported measurements found for this reception. Cannot create a testing report.");
            }

            foreach (var data in reportTestData)
            {
                for (var i = 0; i < data.RawValues.Count; i++)
                {
                    var value = data.RawValues[i];
                    if (value != null)
                    {
                        _context.ReportTests.Add(new ReportTest
                        {
                            ReportId = newReport.Id,
                            MeasurementId = data.MeasurementId,
                            TestId = data.TestId,
                            Idx = i,
                            Value = (decimal)value
                        });
                    }
                }
            }

            var measurements = await _context.Measurements
                .Where(m => m.ReceptionId == reception_id && m.IsReported)
                .ToListAsync();

            foreach (var m in measurements)
            {
                m.IsReadonly = true;
            }

            await _context.SaveChangesAsync();

            // Refresh change tracker or ensure context has persisted data ready for signing
            await _signatureService.SignEntityAsync(
                "reports",
                newReport.Id,
                dto.UserId,
                "Submission",
                "127.0.0.1",
                dto.Comments,
                _context);

            await transaction.CommitAsync();

            return new() { Id = newReport.Id };
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    // GET /receptions/:reception_id/check_report_conflict
    public async Task<bool> CheckReportConflict(long reception_id)
    {
        var report = await _context.Reports.FirstOrDefaultAsync(r => r.ReceptionId == reception_id && !r.IsCancelled);
        if (report == null) return false;

        var conflict = await _context.CertificateTests
            .Include(ct => ct.Certificate)
            .AnyAsync(ct => ct.ReportId == report.Id && 
                            ct.Certificate.IsSubmitted && 
                            !ct.Certificate.IsCancelled && 
                            ct.Certificate.IsConformingSpec);

        return conflict;
    }

    // GET /receptions/:reception_id/measurement_tests
    public async Task<List<MeasurementTestDetailDto>> GetReceptionMeasurementTests(long reception_id)
    {
        var measurements = await _context.Measurements
            .Where(m => m.ReceptionId == reception_id && !m.FormId.HasValue)
            .ToListAsync();

        var measurementsList = new List<MeasurementTestDetailDto>();
        foreach (var m in measurements)
        {
            var dto = await GetMeasurementTestData(m.Id);
            if (dto != null) measurementsList.Add(dto);
        }

        return measurementsList;
    }

    // GET /receptions/:reception_id/measurement_params
    public async Task<List<MeasurementParamDetailDto>> GetReceptionMeasurementParams(long reception_id)
    {
        var measurements = await _context.Measurements
            .Where(m => m.ReceptionId == reception_id && m.FormId.HasValue)
            .ToListAsync();

        var measurementsList = new List<MeasurementParamDetailDto>();
        foreach (var m in measurements)
        {
            var dto = await GetMeasurementParamData(m.Id);
            if (dto != null) measurementsList.Add(dto);
        }

        return measurementsList;
    }

    public async Task<PreviewReportDto> GetPreviewReport(long receptionId)
    {
        var reception = await _context.Receptions
            .Include(r => r.Type)
            .Include(r => r.ControlCode).ThenInclude(cc => cc.Material)
            .Include(r => r.UserSubmitted)
            .FirstOrDefaultAsync(r => r.Id == receptionId);

        if (reception == null) throw new ArgumentException("Reception not found");

        var isCertification = reception.TypeId == 1;
        var dto = new PreviewReportDto
        {
            ReceptionId = receptionId,
            MaterialName = reception.ControlCode?.Material?.Name ?? reception.MaterialName,
            ControlCodeName = reception.ControlCode?.Code,
            ReceptionTypeName = reception.Type.Name,
            UserSubmittedTag = reception.UserSubmitted?.Tag,
            DateSubmitted = reception.DateSubmitted,
            CommentsSubmitted = reception.CommentsSubmitted,
            IsCertification = isCertification
        };

        var allTests = await _context.Tests.Include(t => t.Type).Include(t => t.Unit).Include(t => t.TestEnums).ToListAsync();
        
        var measurementTests = await GetReceptionMeasurementTests(receptionId);
        var measurementParams = await GetReceptionMeasurementParams(receptionId);

        var reportTestData = await GetReportTestDataInternal(receptionId);
        var testsList = new List<PreviewTestRowDto>();

        Spec? activeSpec = null;
        if (isCertification && reception.ControlCode?.MaterialId != null)
        {
            activeSpec = await _context.Specs
                .Include(s => s.SpecTests)
                .FirstOrDefaultAsync(s => s.MaterialId == reception.ControlCode.MaterialId && s.IsSubmitted && !s.IsCancelled);
            dto.ActiveSpecId = activeSpec?.Id;
        }

        foreach (var data in reportTestData)
        {
            var test = data.TestInfo!;
            var row = new PreviewTestRowDto
            {
                MeasurementId = data.MeasurementId,
                HasForm = data.HasForm,
                NrOrd = data.NrOrd,
                TestId = data.TestId,
                TestName = test.Name,
                TypeName = test.IsArray ? $"[{test.Type.Name}]" : test.Type.Name,
                UnitName = test.Unit?.Name,
                FormattedValues = data.FormattedValues
            };
            
            if (isCertification && activeSpec != null)
            {
                var specTest = activeSpec.SpecTests.FirstOrDefault(st => st.TestId == row.TestId);
                if (specTest != null)
                {
                    row.SpecNote = specTest.Note;
                    if (!string.IsNullOrEmpty(specTest.Condition))
                    {
                        foreach (var val in data.RawValues)
                        {
                            if (val.HasValue)
                            {
                                var evalParams = new Dictionary<string, decimal> { { "value", val.Value } };
                                try
                                {
                                    var result = QCFormula.Formula.EvaluateFormula(specTest.Condition, evalParams);
                                    if (result is bool b) row.ConformingResults.Add(b);
                                    else if (result is decimal d) row.ConformingResults.Add(d != 0);
                                    else row.ConformingResults.Add(null);
                                }
                                catch { row.ConformingResults.Add(false); }
                            }
                            else
                            {
                                row.ConformingResults.Add(null);
                            }
                        }
                    }
                }
            }
            testsList.Add(row);
        }

        dto.Tests = testsList
            .OrderBy(t => t.MeasurementId)
            .ThenBy(t => t.NrOrd)
            .ToList();

        return dto;
    }

    private List<decimal?> GetRawValues(MeasurementTestDto t)
    {
        var res = new List<decimal?>();
        if (t.Value is IEnumerable<decimal> enumerable)
        {
            foreach (var v in enumerable) res.Add(v);
        }
        else if (t.Value is decimal d)
        {
            res.Add(d);
        }
        else if (t.Value != null && decimal.TryParse(t.Value.ToString(), out decimal parsed))
        {
            res.Add(parsed);
        }
        return res;
    }

    private List<string> FormatValues(MeasurementTestDto t, Test test)
    {
        List<string> rawValues = new();
        if (t.Value is IEnumerable<decimal> enumerable)
        {
            foreach (var v in enumerable) rawValues.Add(v.ToString());
        }
        else
        {
            rawValues.Add(t.Value?.ToString() ?? "");
        }

        if (test.TypeId == 3) // Boolean
        {
            return rawValues.Select(v => v == "1" || v.ToLower() == "true" ? "Yes" : "No").ToList();
        }
        if (test.TypeId == 4 && test.TestEnums != null) // Enum
        {
            return rawValues.Select(v => test.TestEnums.FirstOrDefault(e => e.Value.ToString() == v)?.Name ?? v).ToList();
        }
        
        return rawValues;
    }

    private class InternalReportTestData
    {
        public long MeasurementId { get; set; }
        public long TestId { get; set; }
        public int Idx { get; set; } // TODO: delete this field
        public decimal Value { get; set; } // TODO: delete this field
        public bool HasForm { get; set; }
        public long NrOrd { get; set; }
        
        // Extra info for preview
        public Test? TestInfo { get; set; }
        public List<string> FormattedValues { get; set; } = new();
        public List<decimal?> RawValues { get; set; } = new();
    }

    private async Task<List<InternalReportTestData>> GetReportTestDataInternal(long receptionId)
    {
        var allTests = await _context.Tests.Include(t => t.Type).Include(t => t.Unit).Include(t => t.TestEnums).ToListAsync();
        
        var measurementTests = await GetReceptionMeasurementTests(receptionId);
        var measurementParams = await GetReceptionMeasurementParams(receptionId);

        var reportedTests = measurementTests.Where(m => m.IsReported).ToList();
        var reportedParams = measurementParams.Where(m => m.IsReported).ToList();

        var result = new List<InternalReportTestData>();

        foreach (var m in reportedTests)
        {
            if (m.Tests != null)
            {
                foreach (var t in m.Tests)
                {
                    var test = allTests.First(x => x.Id == t.TestId);
                    
                    var data = new InternalReportTestData
                    {
                        MeasurementId = m.Id,
                        TestId = t.TestId,
                        Idx = 0,
                        Value = t.Value is decimal d ? d : (decimal.TryParse(t.Value?.ToString(), out decimal dv) ? dv : 0),
                        HasForm = false,
                        NrOrd = test.NrOrd,
                        TestInfo = test,
                        FormattedValues = FormatValues(t, test),
                        RawValues = GetRawValues(t)
                    };
                    result.Add(data);
                }
            }
        }

        foreach (var m in reportedParams)
        {
            var formParamsSchema = await _formsService.GetFormParams(m.FormId);

            var measurementParamsRows = await _context.MeasurementParams
                .Where(mp => mp.MeasurementId == m.Id && mp.FormId == m.FormId)
                .ToListAsync();

            var flatParams = measurementParamsRows.Select(mp => new MeasurementFlatData { TestId = mp.TestId, Idx = mp.Idx, Value = mp.Value }).ToList();
            var allDataDict = FormEvalMapper.MapFlatToDict(flatParams, formParamsSchema);

            foreach (var kvp in allDataDict)
            {
                if (kvp.Value == null) continue;
                
                var paramInfo = formParamsSchema.FirstOrDefault(p => p.Code == kvp.Key);
                if (paramInfo == null) continue;

                var test = allTests.First(x => x.Id == paramInfo.TestId);
                if (test.IsParam) continue; // Skip parameters, only include tests (!) in report

                if (paramInfo.IsArray && kvp.Value is ICollection<decimal?> list)
                {
                    var decimalList = list.Where(v => v.HasValue).Select(v => v!.Value).ToList();
                    var data = new InternalReportTestData
                    {
                        MeasurementId = m.Id,
                        TestId = test.Id,
                        Idx = 0,
                        Value = decimalList.FirstOrDefault(),
                        HasForm = true,
                        NrOrd = paramInfo.NrOrd,
                        TestInfo = test
                    };
                    var mockT = new MeasurementTestDto { TestId = test.Id, Value = decimalList };
                    data.FormattedValues.AddRange(FormatValues(mockT, test));
                    data.RawValues.AddRange(GetRawValues(mockT));
                    result.Add(data);
                }
                else if (!paramInfo.IsArray)
                {
                    decimal val = kvp.Value is decimal d ? d : (decimal.TryParse(kvp.Value.ToString(), out decimal dv) ? dv : 0);
                    var data = new InternalReportTestData
                    {
                        MeasurementId = m.Id,
                        TestId = test.Id,
                        Idx = 0,
                        Value = val,
                        HasForm = true,
                        NrOrd = paramInfo.NrOrd,
                        TestInfo = test
                    };
                    var mockT = new MeasurementTestDto { TestId = test.Id, Value = kvp.Value };
                    data.FormattedValues.AddRange(FormatValues(mockT, test));
                    data.RawValues.AddRange(GetRawValues(mockT));
                    result.Add(data);
                }
            }
        }

        return result;
    }

    public async Task<ExpressCertificateResultDto> SubmitExpressCertificate(long reception_id, ExpressCertificateDto dto)
    {
        var reception = await _context.Receptions
            .Include(r => r.ControlCode)
            .FirstOrDefaultAsync(r => r.Id == reception_id);

        if (reception == null)
        {
            return new ExpressCertificateResultDto { Success = false, ErrorMessage = "Reception not found." };
        }

        if (reception.TypeId != 1 || !reception.ControlCodeId.HasValue)
        {
            return new ExpressCertificateResultDto { Success = false, ErrorMessage = "Express certification is only allowed for certification samples." };
        }

        long controlCodeId = reception.ControlCodeId.Value;
        long materialId = reception.ControlCode!.MaterialId;

        // 1. Check whether a certificate (in any status Draft, Submitted, Canceled) is already present for the current batch (control_code_id) in database table 'certificates'
        var anyCertExists = await _context.Certificates
            .AnyAsync(c => c.ControlCodeId == controlCodeId);

        if (anyCertExists)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = "A quality certificate (Draft, Submitted, or Canceled) is already present for this batch (control code)."
            };
        }

        // 2. Check whether there is a valid testing report (Submitted but not Canceled) already present in database table 'reports' but on a different sample reception for the same batch
        var validReportOnOtherReceptionExists = await _context.Reports
            .Include(r => r.Reception)
            .AnyAsync(r => r.Reception.ControlCodeId == controlCodeId && r.ReceptionId != reception_id && r.IsSubmitted && !r.IsCancelled);

        if (validReportOnOtherReceptionExists)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = "A valid testing report already exists on a different sample reception for this batch."
            };
        }

        // 3. If first 2 conditions are met, assess test result conformity in memory without writing any data to DB
        var activeSpec = await _context.Specs
            .Where(s => s.MaterialId == materialId && s.IsSubmitted && !s.IsCancelled)
            .OrderByDescending(s => s.Id)
            .FirstOrDefaultAsync();

        if (activeSpec == null)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = "No valid active specification found for this material."
            };
        }

        var inFlightReportData = await GetReportTestDataInternal(reception_id);
        if (inFlightReportData.Count == 0)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = "No reported measurements found for this reception. Cannot create a testing report or certificate."
            };
        }

        var inFlightTestRows = new List<(long MeasurementId, bool HasForm, long TestId, decimal Value, int Idx)>();
        foreach (var data in inFlightReportData)
        {
            for (var i = 0; i < data.RawValues.Count; i++)
            {
                var val = data.RawValues[i];
                if (val.HasValue)
                {
                    inFlightTestRows.Add((data.MeasurementId, data.HasForm, data.TestId, val.Value, i));
                }
            }
        }

        var analysis = await _certificatesService.AnalyzeInFlightResults(activeSpec.Id, controlCodeId, inFlightTestRows);
        if (!analysis.IsConformingSpec)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = $"Conformity verification failed:\n{analysis.AnalysisResult}"
            };
        }

        // 4. Everything is OK -> submit testing report (reusing CreateReport) and then issue quality certificate (reusing GenerateCertificate and SubmitCertificate)
        var reportIdDto = await CreateReport(reception_id, new CreateReportDto
        {
            UserId = dto.UserId,
            Comments = dto.Comments
        });

        var generateDto = new GenerateCertificateDto
        {
            MaterialId = materialId,
            ControlCodeId = controlCodeId,
            UserId = dto.UserId
        };

        var certDetail = await _certificatesService.GenerateCertificate(generateDto);
        if (certDetail == null)
        {
            return new ExpressCertificateResultDto
            {
                Success = false,
                ErrorMessage = "Failed to generate quality certificate."
            };
        }

        await _certificatesService.SubmitCertificate(certDetail.Id, new CertificateActionDto
        {
            UserId = dto.UserId,
            CommentsSubmitted = dto.Comments
        });

        return new ExpressCertificateResultDto
        {
            Success = true,
            CertificateId = certDetail.Id
        };
    }
}
