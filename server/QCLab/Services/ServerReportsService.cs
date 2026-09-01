using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerReportsService : IReportsService
{
    private readonly QualityControlContext _context;
    private readonly ElectronicSignatureService _signatureService;

    public ServerReportsService(QualityControlContext context, ElectronicSignatureService signatureService)
    {
        _context = context;
        _signatureService = signatureService;
    }

    // GET /reports
    public async Task<PaginatedReportsDto> GetAllReports(
        int page,
        int pageSize,
        long userId,
        long? receptionTypeId = null,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null)
    {
        var query = _context.Reports
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Type)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.ControlCode)
                    .ThenInclude(cc => cc.Material)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Category)
            .Include(r => r.UserSubmitted)
            .Where(r => !r.IsCancelled)
            .AsQueryable();

        if (receptionTypeId.HasValue)
        {
            query = query.Where(r => r.Reception.TypeId == receptionTypeId);
        }

        if (materialId.HasValue)
        {
            query = query.Where(r => r.Reception.ControlCode != null && r.Reception.ControlCode.MaterialId == materialId);
        }

        if (submissionYear.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Year == submissionYear.Value);
        }

        if (submissionMonth.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Month == submissionMonth.Value);
        }

        var totalCount = await query.CountAsync();
        var reports = await query
            .OrderByDescending(r => r.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var reportsList = reports.Select(r =>
        {
            string? matName = r.Reception.MaterialName;
            string? ccCat = r.Reception.Category?.Name;

            if (r.Reception.TypeId == 1 || r.Reception.TypeId == 2)
            {
                matName = r.Reception.ControlCode?.Material?.Name ?? matName;
                ccCat = r.Reception.ControlCode?.Code;
            }

            return new ReportDto
            {
                Id = r.Id,
                UserSubmittedTag = r.UserSubmitted?.Tag,
                DateSubmitted = r.DateSubmitted,
                ReceptionTypeName = r.Reception.Type.Name,
                MaterialName = matName,
                ControlCodeCategory = ccCat
            };
        }).ToList();

        return new PaginatedReportsDto
        {
            Reports = reportsList,
            TotalCount = totalCount,
            PageSize = pageSize,
            CurrentPage = page
        };
    }

    // GET /reports/{id}
    public async Task<ReportDetailDto?> GetReport(long id)
    {
        var report = await _context.Reports
            .Include(r => r.UserSubmitted)
            .Include(r => r.UserCancelled)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Type)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.ControlCode)
                    .ThenInclude(cc => cc.Material)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Category)
            .FirstOrDefaultAsync(r => r.Id == id);

        if (report == null) return null;

        var reportTests = await _context.ReportTests
            .Include(rt => rt.Measurement)
            .Include(rt => rt.Test)
                .ThenInclude(t => t.Unit)
            .Include(rt => rt.Test)
                .ThenInclude(t => t.TestEnums)
            .Include(rt => rt.Test)
                .ThenInclude(t => t.Type)
            .Where(rt => rt.ReportId == id)
            .ToListAsync();

        var processedTests = new List<ReportTestDto>();
        // Group by MeasurementId
        var groupedByMeasurement = reportTests.GroupBy(rt => rt.MeasurementId);

        foreach (var mGroup in groupedByMeasurement)
        {
            var mId = mGroup.Key;
            var testGroups = mGroup.GroupBy(rt => rt.TestId);
            bool hasForm = mGroup.First().Measurement.FormId.HasValue;

            foreach (var tGroup in testGroups)
            {
                var first = tGroup.First();
                var test = first.Test;
                string typeName = test.Type?.Name ?? "";
                long nrOrd = test.NrOrd;

                var dto = new ReportTestDto
                {
                    MeasurementId = mId,
                    HasForm = hasForm,
                    NrOrd = nrOrd,
                    TestName = test.Name,
                    TypeName = test.IsArray ? $"[{typeName}]" : typeName,
                    UnitName = test.Unit?.Name,
                };

                var sortedResults = tGroup.OrderBy(rt => rt.Idx).ToList();
                foreach (var rt in sortedResults)
                {
                    string displayVal = rt.Value.ToString();
                    if (test.TypeId == 4) // Enum
                    {
                        var intVal = (long)rt.Value;
                        var enumVal = test.TestEnums.FirstOrDefault(e => e.Value == intVal);
                        if (enumVal != null) displayVal = enumVal.Name;
                    }
                    else if (test.TypeId == 3) // Boolean
                    {
                        displayVal = rt.Value == 1 ? "Yes" : "No";
                    }
                    else if (rt.Value % 1 == 0)
                    {
                        displayVal = rt.Value.ToString("F1");
                    }
                    dto.FormattedValues.Add(displayVal);

                    string uncertaintyDisplay = "";
                    if (rt.UncertaintyValue.HasValue && rt.CoverageFactorK.HasValue)
                    {
                        uncertaintyDisplay = $"±{rt.UncertaintyValue.Value.ToString("G29")} (k = {rt.CoverageFactorK.Value.ToString("G29")})";
                    }
                    dto.UncertaintyValues.Add(uncertaintyDisplay);
                }
                dto.Value = string.Join(", ", dto.FormattedValues);
                processedTests.Add(dto);
            }
        }

        processedTests = processedTests
            .OrderBy(t => t.MeasurementId)
            .ThenBy(t => t.NrOrd)
            .ToList();

        string? matName = report.Reception.MaterialName;
        if (report.Reception.TypeId == 1 || report.Reception.TypeId == 2)
        {
            matName = report.Reception.ControlCode?.Material?.Name ?? matName;
        }

        return new ReportDetailDto
        {
            Id = report.Id,
            ReceptionId = report.ReceptionId,
            IsSubmitted = report.IsSubmitted,
            UserSubmittedId = report.UserSubmittedId,
            UserSubmittedTag = report.UserSubmitted?.Tag,
            DateSubmitted = report.DateSubmitted,
            CommentsSubmitted = report.CommentsSubmitted,
            ReportReplacedId = report.ReportReplacedId,
            IsCancelled = report.IsCancelled,
            UserCancelledId = report.UserCancelledId,
            UserCancelledTag = report.UserCancelled?.Tag,
            DateCancelled = report.DateCancelled,
            CommentsCancelled = report.CommentsCancelled,
            MaterialName = matName,
            ControlCode = report.Reception.ControlCode?.Code,
            ReceptionTypeName = report.Reception.Type.Name,
            IsCertification = report.Reception.TypeId == 1,
            Tests = processedTests
        };
    }

    // PUT /reports/{id}/cancel
    public async Task CancelReport(long id, CancelReportDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("user_id is required");

        var conflict = await _context.CertificateTests
            .Include(ct => ct.Certificate)
            .AnyAsync(ct => ct.ReportId == id && 
                            ct.Certificate.IsSubmitted && 
                            !ct.Certificate.IsCancelled);

        if (conflict)
        {
            throw new InvalidOperationException("This report is part of a submitted certificate and cannot be cancelled.");
        }

        var report = await _context.Reports.FindAsync(id);
        if (report == null) throw new ArgumentException("Report not found");

        report.IsCancelled = true;
        report.UserCancelledId = dto.UserId;
        report.DateCancelled = DateTime.UtcNow;
        report.CommentsCancelled = dto.CommentsCancelled;

        await _context.SaveChangesAsync();

        await _signatureService.SignEntityAsync(
            "reports",
            id,
            dto.UserId,
            "Cancellation",
            "127.0.0.1",
            dto.CommentsCancelled);
    }

    public async Task<bool> CheckReportConflict(long id)
    {
        return await _context.CertificateTests
            .Include(ct => ct.Certificate)
            .AnyAsync(ct => ct.ReportId == id && 
                            ct.Certificate.IsSubmitted && 
                            !ct.Certificate.IsCancelled);
    }

    public async Task<byte[]?> ExportReportsExcel(
        long? receptionTypeId = null,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null,
        int? loadedPages = null,
        int pageSize = 15,
        IHttpClientFactory? clientFactory = null)
    {
        var query = _context.Reports
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Type)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.ControlCode)
                    .ThenInclude(cc => cc.Material)
            .Include(r => r.Reception)
                .ThenInclude(rec => rec.Category)
            .Where(r => !r.IsCancelled)
            .AsQueryable();

        if (receptionTypeId.HasValue)
        {
            query = query.Where(r => r.Reception.TypeId == receptionTypeId);
        }

        if (materialId.HasValue)
        {
            query = query.Where(r => r.Reception.ControlCode != null && r.Reception.ControlCode.MaterialId == materialId);
        }

        if (submissionYear.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Year == submissionYear.Value);
        }

        if (submissionMonth.HasValue)
        {
            query = query.Where(r => r.DateSubmitted.HasValue && r.DateSubmitted.Value.Month == submissionMonth.Value);
        }

        var orderedQuery = query.OrderByDescending(r => r.Id);

        List<Report> reports;
        if (loadedPages.HasValue && loadedPages.Value > 0)
        {
            reports = await orderedQuery.Take(loadedPages.Value * pageSize).ToListAsync();
        }
        else
        {
            reports = await orderedQuery.ToListAsync();
        }

        if (!reports.Any())
        {
            // Return empty excel payload request or let python handle empty sheets
        }

        // Group reports by Reception Type (TypeId: 1 = Certification, 2 = Verification, 3 = Category Verification)
        // Ordered as 'Certification', 'Verification', 'Category Verification', and sorted ascending by material/category name respectively.
        var sheets = new List<SheetExportDto>();

        // 1. Certification (TypeId == 1) sorted ascending by material name
        var certReports = reports.Where(r => r.Reception.TypeId == 1).ToList();
        var certByMaterial = certReports
            .Where(r => r.Reception.ControlCode?.Material != null)
            .GroupBy(r => r.Reception.ControlCode!.MaterialId)
            .OrderBy(g => g.First().Reception.ControlCode!.Material!.Name);

        foreach (var matGroup in certByMaterial)
        {
            var mat = matGroup.First().Reception.ControlCode!.Material!;
            var matName = mat.Name;
            var sheetLabel = $"C {matName}";
            var sheetTitle = $"{matName} (Certification)";

            var tests = await _context.Materials
                .Where(m => m.Id == mat.Id)
                .SelectMany(m => m.Tests)
                .Include(t => t.Type)
                .Include(t => t.Unit)
                .OrderBy(t => t.NrOrd)
                .ToListAsync();

            var testColumns = tests.Select(t => new TestColumnDto
            {
                TestId = t.Id,
                Name = t.Name,
                NrOrd = t.NrOrd
            }).ToList();

            var rows = await BuildExportRows(matGroup.ToList(), tests);

            sheets.Add(new SheetExportDto
            {
                SheetLabel = sheetLabel,
                SheetTitle = sheetTitle,
                IsCategory = false,
                Tests = testColumns,
                Rows = rows
            });
        }

        // 2. Verification (TypeId == 2) sorted ascending by material name
        var verReports = reports.Where(r => r.Reception.TypeId == 2).ToList();
        var verByMaterial = verReports
            .Where(r => r.Reception.ControlCode?.Material != null)
            .GroupBy(r => r.Reception.ControlCode!.MaterialId)
            .OrderBy(g => g.First().Reception.ControlCode!.Material!.Name);

        foreach (var matGroup in verByMaterial)
        {
            var mat = matGroup.First().Reception.ControlCode!.Material!;
            var matName = mat.Name;
            var sheetLabel = $"V {matName}";
            var sheetTitle = $"{matName} (Verification)";

            var tests = await _context.Materials
                .Where(m => m.Id == mat.Id)
                .SelectMany(m => m.Tests)
                .Include(t => t.Type)
                .Include(t => t.Unit)
                .OrderBy(t => t.NrOrd)
                .ToListAsync();

            var testColumns = tests.Select(t => new TestColumnDto
            {
                TestId = t.Id,
                Name = t.Name,
                NrOrd = t.NrOrd
            }).ToList();

            var rows = await BuildExportRows(matGroup.ToList(), tests);

            sheets.Add(new SheetExportDto
            {
                SheetLabel = sheetLabel,
                SheetTitle = sheetTitle,
                IsCategory = false,
                Tests = testColumns,
                Rows = rows
            });
        }

        // 3. Category Verification (TypeId == 3) sorted ascending by category name
        var catVerReports = reports.Where(r => r.Reception.TypeId == 3).ToList();
        var catVerByCategory = catVerReports
            .Where(r => r.Reception.Category != null)
            .GroupBy(r => r.Reception.CategoryId)
            .OrderBy(g => g.First().Reception.Category!.Name);

        foreach (var catGroup in catVerByCategory)
        {
            var cat = catGroup.First().Reception.Category!;
            var catName = cat.Name;
            var sheetLabel = $"CV {catName}";
            var sheetTitle = $"{catName} (Category Verification)";

            var tests = await _context.Categories
                .Where(c => c.Id == cat.Id)
                .SelectMany(c => c.Tests)
                .Include(t => t.Type)
                .Include(t => t.Unit)
                .OrderBy(t => t.NrOrd)
                .ToListAsync();

            var testColumns = tests.Select(t => new TestColumnDto
            {
                TestId = t.Id,
                Name = t.Name,
                NrOrd = t.NrOrd
            }).ToList();

            var rows = await BuildExportRows(catGroup.ToList(), tests, isCategory: true);

            sheets.Add(new SheetExportDto
            {
                SheetLabel = sheetLabel,
                SheetTitle = sheetTitle,
                IsCategory = true,
                Tests = testColumns,
                Rows = rows
            });
        }

        var payload = new TestingReportsExportRequestDto { Sheets = sheets };

        if (clientFactory == null) return null;

        var httpClient = clientFactory.CreateClient();
        var baseUrl = Environment.GetEnvironmentVariable("REPORTING_XL_URL") ?? Environment.GetEnvironmentVariable("PYTHON_REPORTING_URL") ?? Environment.GetEnvironmentVariable("REPORTING_SERVICE_URL") ?? "http://reporting_xl:8000";
        var reportingUrl = $"{baseUrl.TrimEnd('/')}/testing-reports-excel";

        var response = await httpClient.PostAsJsonAsync(reportingUrl, payload);
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException($"Failed to generate Excel from reporting service: {response.StatusCode} - {err}");
        }

        return await response.Content.ReadAsByteArrayAsync();
    }

    private async Task<List<ReportExportRowDto>> BuildExportRows(List<Report> reports, List<Test> applicableTests, bool isCategory = false)
    {
        var reportIds = reports.Select(r => r.Id).ToList();
        var reportTests = await _context.ReportTests
            .Include(rt => rt.Measurement)
            .Include(rt => rt.Test)
                .ThenInclude(t => t.TestEnums)
            .Where(rt => reportIds.Contains(rt.ReportId))
            .ToListAsync();

        var applicableTestIds = applicableTests.Select(t => t.Id).ToHashSet();
        var resultRows = new List<ReportExportRowDto>();

        foreach (var report in reports)
        {
            var repTests = reportTests.Where(rt => rt.ReportId == report.Id).ToList();
            if (!repTests.Any()) continue;

            var measurements = repTests.GroupBy(rt => rt.MeasurementId).ToList();

            string dateSubStr = report.DateSubmitted.HasValue ? report.DateSubmitted.Value.ToString("yyyy-MM-dd HH:mm") : string.Empty;
            string? controlCode = report.Reception.ControlCode?.Code;
            string? materialName = report.Reception.MaterialName ?? report.Reception.ControlCode?.Material?.Name;

            foreach (var mGroup in measurements)
            {
                long measurementId = mGroup.Key;
                bool hasForm = mGroup.First().Measurement.FormId.HasValue;

                var testValueDtos = new List<ReportTestValueDto>();

                foreach (var test in applicableTests)
                {
                    var tResults = mGroup.Where(rt => rt.TestId == test.Id).OrderBy(rt => rt.Idx).ToList();
                    var formattedValues = new List<string>();

                    foreach (var rt in tResults)
                    {
                        string displayVal = rt.Value.ToString();
                        if (test.TypeId == 4) // Enum
                        {
                            var intVal = (long)rt.Value;
                            var enumVal = test.TestEnums.FirstOrDefault(e => e.Value == intVal);
                            if (enumVal != null) displayVal = enumVal.Name;
                        }
                        else if (test.TypeId == 3) // Boolean
                        {
                            displayVal = rt.Value == 1 ? "Yes" : "No";
                        }
                        else if (rt.Value % 1 == 0)
                        {
                            displayVal = rt.Value.ToString("F1");
                        }
                        formattedValues.Add(displayVal);
                    }

                    if (!formattedValues.Any())
                    {
                        formattedValues.Add("");
                    }

                    testValueDtos.Add(new ReportTestValueDto
                    {
                        TestId = test.Id,
                        Values = formattedValues
                    });
                }

                resultRows.Add(new ReportExportRowDto
                {
                    ReportId = report.Id,
                    DateSubmitted = dateSubStr,
                    ControlCode = controlCode,
                    MaterialName = materialName,
                    MeasurementId = measurementId,
                    HasForm = hasForm,
                    TestValues = testValueDtos
                });
            }
        }

        return resultRows;
    }
}


