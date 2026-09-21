using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCFormula;

namespace QCLab.Services;

public class ServerCertificatesService : ICertificatesService
{
    private readonly QualityControlContext _context;
    private readonly ElectronicSignatureService _signatureService;

    public ServerCertificatesService(QualityControlContext context, ElectronicSignatureService signatureService)
    {
        _context = context;
        _signatureService = signatureService;
    }

    // Helper to calculate and save certificate tests
    private async Task CalculateAndSaveCertificateTests(long certificateId, long specId, long controlCodeId)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // 0. Get certified test IDs
            var certifiedTestIds = await _context.Tests
                .Where(t => t.ForCertification && !t.IsObsolete)
                .Select(t => t.Id)
                .ToListAsync();

            // 1. Get spec_tests for the current spec
            var specTests = await _context.SpecTests
                .Where(st => st.SpecId == specId && certifiedTestIds.Contains(st.TestId))
                .ToListAsync();
            var specTestsMap = specTests.ToDictionary(st => st.TestId, st => st);

            // 2. Find relevant reports
            var receptionIds = await _context.Receptions
                .Where(r => r.ControlCodeId == controlCodeId && r.TypeId == 1)
                .Select(r => r.Id)
                .ToListAsync();

            var reportIds = new List<long>();
            if (receptionIds.Count > 0)
            {
                reportIds = await _context.Reports
                    .Where(r => receptionIds.Contains(r.ReceptionId) && r.IsSubmitted && !r.IsCancelled)
                    .Select(r => r.Id)
                    .ToListAsync();
            }

            // 3. Gather tests from current reports
            var certificateTestsToCreate = new List<CertificateTest>();
            var commentsForCertificate = new List<string>();
            long noteCounter = 1;

            if (reportIds.Count > 0)
            {
                var specTestIds = specTestsMap.Keys.ToList();
                var reportTests = await _context.ReportTests
                    .Where(rt => reportIds.Contains(rt.ReportId) && specTestIds.Contains(rt.TestId))
                    .ToListAsync();

                foreach (var reportTest in reportTests)
                {
                    if (specTestsMap.TryGetValue(reportTest.TestId, out var specTest))
                    {
                        var value = reportTest.Value;
                        var condition = specTest.Condition;
                        bool isConformingSpec = false;
                        bool isConformingUncertainty = true;

                        if (!string.IsNullOrEmpty(condition))
                        {
                            try
                            {
                                var params_ = new Dictionary<string, decimal> { { "value", value } };
                                var result = QCFormula.Formula.EvaluateFormula(condition, params_);
                                if (result is bool b) isConformingSpec = b;
                                else if (result is decimal d) isConformingSpec = d != 0;
                            }
                            catch (Exception e)
                            {
                                Console.Error.WriteLine($"Error evaluating formula '{condition}' with value {value}: {e}");
                            }

                            if (reportTest.UncertaintyValue.HasValue && reportTest.CoverageFactorK.HasValue)
                            {
                                var u = reportTest.UncertaintyValue.Value * reportTest.CoverageFactorK.Value;
                                var valMinusU = value - u;
                                var valPlusU = value + u;
                                bool confMinus = false;
                                bool confPlus = false;
                                try
                                {
                                    var resMinus = QCFormula.Formula.EvaluateFormula(condition, new Dictionary<string, decimal> { { "value", valMinusU } });
                                    if (resMinus is bool bm) confMinus = bm;
                                    else if (resMinus is decimal dm) confMinus = dm != 0;

                                    var resPlus = QCFormula.Formula.EvaluateFormula(condition, new Dictionary<string, decimal> { { "value", valPlusU } });
                                    if (resPlus is bool bp) confPlus = bp;
                                    else if (resPlus is decimal dp) confPlus = dp != 0;

                                    isConformingUncertainty = confMinus && confPlus;
                                }
                                catch (Exception e)
                                {
                                    Console.Error.WriteLine($"Error evaluating uncertainty formula '{condition}' with value {value}: {e}");
                                    isConformingUncertainty = false;
                                }
                            }
                            else
                            {
                                isConformingUncertainty = true;
                            }
                        }

                        var noteSpec = specTest.Note;
                        if (!string.IsNullOrEmpty(noteSpec) && noteSpec.Length > 25)
                        {
                            commentsForCertificate.Add($"[{noteCounter}] {specTest.Note}");
                            noteSpec = $"[{noteCounter}]";
                            noteCounter++;
                        }

                        certificateTestsToCreate.Add(new CertificateTest
                        {
                            CertificateId = certificateId,
                            ReportId = reportTest.ReportId,
                            MeasurementId = reportTest.MeasurementId,
                            TestId = reportTest.TestId,
                            Idx = reportTest.Idx,
                            Value = value,
                            UncertaintyValue = reportTest.UncertaintyValue,
                            CoverageFactorK = reportTest.CoverageFactorK,
                            TestCount = 1,
                            NoteSpec = noteSpec ?? string.Empty,
                            IsConformingSpec = isConformingSpec,
                            IsConformingUncertainty = isConformingUncertainty
                        });
                    }
                }
            }

            // 4. Find previous certificate and carry over tests
            var controlCode = await _context.ControlCodes.FindAsync(controlCodeId);
            if (controlCode != null)
            {
                var previousCert = await _context.Certificates
                    .Include(c => c.ControlCode)
                    .Where(c => c.ControlCode.MaterialId == controlCode.MaterialId &&
                                c.ControlCodeId < controlCodeId &&
                                c.IsSubmitted &&
                                !c.IsCancelled &&
                                c.IsConformingSpec &&
                                c.IsConformingUncertainty)
                    .OrderByDescending(c => c.ControlCodeId)
                    .FirstOrDefaultAsync();

                if (previousCert != null)
                {
                    var previousCertTests = await _context.CertificateTests
                        .Where(ct => ct.CertificateId == previousCert.Id)
                        .ToListAsync();

                    var currentTestIds = new HashSet<long>(certificateTestsToCreate.Select(t => t.TestId));

                    foreach (var prevTest in previousCertTests)
                    {
                        if (specTestsMap.TryGetValue(prevTest.TestId, out var specTestInfo))
                        {
                            if (!currentTestIds.Contains(prevTest.TestId) && (prevTest.TestCount + 1) <= specTestInfo.TestFrequency)
                            {
                                certificateTestsToCreate.Add(new CertificateTest
                                {
                                    CertificateId = certificateId,
                                    ReportId = prevTest.ReportId,
                                    MeasurementId = prevTest.MeasurementId,
                                    TestId = prevTest.TestId,
                                    Idx = prevTest.Idx,
                                    Value = prevTest.Value,
                                    UncertaintyValue = prevTest.UncertaintyValue,
                                    CoverageFactorK = prevTest.CoverageFactorK,
                                    TestCount = prevTest.TestCount + 1,
                                    NoteSpec = prevTest.NoteSpec,
                                    IsConformingSpec = prevTest.IsConformingSpec,
                                    IsConformingUncertainty = prevTest.IsConformingUncertainty
                                });
                            }
                        }
                    }
                }
            }

            // 5. Update certificate comments
            if (commentsForCertificate.Count > 0)
            {
                var cert = await _context.Certificates.FindAsync(certificateId);
                if (cert != null)
                {
                    cert.CommentsSubmitted = string.Join("\n", commentsForCertificate);
                    await _context.SaveChangesAsync();
                }
            }

            // 6. Delete existing certificate_tests and save new ones
            var existingTests = await _context.CertificateTests.Where(ct => ct.CertificateId == certificateId).ToListAsync();
            _context.CertificateTests.RemoveRange(existingTests);
            await _context.SaveChangesAsync();

            if (certificateTestsToCreate.Count > 0)
            {
                _context.CertificateTests.AddRange(certificateTestsToCreate);
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

    // GET /certificates
    public async Task<PaginatedCertificatesDto> GetAllCertificates(
        int page,
        int pageSize,
        bool isQCPersonnel,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null)
    {
        var query = _context.Certificates
            .Include(c => c.ControlCode)
            .ThenInclude(cc => cc.Material)
            .Include(c => c.CertificateTests)
            .ThenInclude(ct => ct.Report)
            .AsQueryable();

        if (!isQCPersonnel)
        {
            query = query.Where(c => c.IsSubmitted && !c.IsCancelled);
        }

        if (materialId.HasValue)
        {
            query = query.Where(c => c.ControlCode.MaterialId == materialId.Value);
        }

        if (submissionYear.HasValue)
        {
            query = query.Where(c => c.DateSubmitted.HasValue && c.DateSubmitted.Value.Year == submissionYear.Value);
        }

        if (submissionMonth.HasValue)
        {
            query = query.Where(c => c.DateSubmitted.HasValue && c.DateSubmitted.Value.Month == submissionMonth.Value);
        }

        var totalCount = await query.CountAsync();
        var certificates = await query
            .OrderByDescending(c => c.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var certsList = certificates.Select(c => {
            var status = "Draft";
            if (c.IsCancelled) status = "Cancelled";
            else if (c.IsSubmitted) status = "Submitted";

            var hasTestFromCancelledReport = c.CertificateTests.Any(ct => ct.Report.IsCancelled);

            return new CertificateDto
            {
                Id = c.Id,
                MaterialName = c.ControlCode.Material.Name,
                ControlCode = c.ControlCode.Code,
                IsConformingSpec = c.IsConformingSpec,
                IsConformingUncertainty = c.IsConformingUncertainty,
                DateSubmitted = c.DateSubmitted,
                CertificateReplacedId = c.CertificateReplacedId,
                DateCancelled = c.DateCancelled,
                IsCancelled = c.IsCancelled,
                IsSubmitted = c.IsSubmitted,
                Status = status,
                HasTestFromCancelledReport = hasTestFromCancelledReport
            };
        }).ToList();

        return new PaginatedCertificatesDto
        {
            Certificates = certsList,
            TotalCount = totalCount,
            PageSize = pageSize,
            CurrentPage = page
        };
    }

    // GET /certificates/{id}
    public async Task<CertificateDetailDto?> GetCertificate(long id)
    {
        var certificate = await _context.Certificates
            .Include(c => c.UserSubmitted)
            .Include(c => c.UserCancelled)
            .Include(c => c.CertificateTests)
                .ThenInclude(ct => ct.Test)
                    .ThenInclude(t => t.Unit)
            .Include(c => c.CertificateTests)
                .ThenInclude(ct => ct.Test)
                    .ThenInclude(t => t.Type)
            .Include(c => c.CertificateTests)
                .ThenInclude(ct => ct.Test)
                    .ThenInclude(t => t.TestEnums)
            .Include(c => c.CertificateTests)
                .ThenInclude(ct => ct.Report)
            .Include(c => c.CertificateTests)
                .ThenInclude(ct => ct.Measurement)
            .Include(c => c.ControlCode)
                .ThenInclude(cc => cc.Material)
            .Include(c => c.Spec)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (certificate == null) return null;

        var status = "Draft";
        if (certificate.IsCancelled) status = "Cancelled";
        else if (certificate.IsSubmitted) status = "Submitted";

        var specTests = await _context.SpecTests
            .Where(st => st.SpecId == certificate.SpecId)
            .ToDictionaryAsync(st => st.TestId, st => st.TestFrequency);

        var processedTests = new List<CertificateTestDto>();
        var groupedByMeasurement = certificate.CertificateTests.GroupBy(ct => ct.MeasurementId);

        foreach (var mGroup in groupedByMeasurement)
        {
            var mId = mGroup.Key;
            var testGroups = mGroup.GroupBy(ct => ct.TestId);
            var firstInMGroup = mGroup.First();
            bool hasForm = firstInMGroup.Measurement.FormId.HasValue;

            foreach (var tGroup in testGroups)
            {
                var first = tGroup.First();
                var test = first.Test;
                string typeName = test.Type?.Name ?? "";
                
                var dto = new CertificateTestDto
                {
                    CertificateId = first.CertificateId,
                    ReportId = first.ReportId,
                    MeasurementId = mId,
                    HasForm = hasForm,
                    NrOrd = test.NrOrd,
                    TestId = first.TestId,
                    TypeId = test.TypeId,
                    TypeName = test.IsArray ? $"[{typeName}]" : typeName,
                    TestCount = first.TestCount,
                    TestFrequency = specTests.TryGetValue(first.TestId, out var freq) ? freq : 0,
                    NoteSpec = first.NoteSpec,
                    IsConformingSpec = tGroup.All(x => x.IsConformingSpec),
                    IsConformingUncertainty = tGroup.All(x => x.IsConformingUncertainty),
                    TestName = test.Name,
                    UnitName = test.Unit?.Name,
                    ReportIsCancelled = first.Report.IsCancelled
                };

                var sortedResults = tGroup.OrderBy(ct => ct.Idx).ToList();
                foreach (var ct in sortedResults)
                {
                    string displayVal = ct.Value.ToString();
                    if (test.TypeId == 4) // Enum
                    {
                        var intVal = (long)ct.Value;
                        var enumVal = test.TestEnums.FirstOrDefault(e => e.Value == intVal);
                        if (enumVal != null) displayVal = enumVal.Name;
                    }
                    else if (test.TypeId == 3) // Boolean
                    {
                        displayVal = ct.Value == 1 ? "Yes" : "No";
                    }
                    else if (ct.Value % 1 == 0)
                    {
                        displayVal = ct.Value.ToString("F1");
                    }
                    dto.FormattedValues.Add(displayVal);

                    string uncertaintyDisplay = "";
                    if (ct.UncertaintyValue.HasValue && ct.CoverageFactorK.HasValue)
                    {
                        uncertaintyDisplay = $"±{ct.UncertaintyValue.Value.ToString("G29")} (k = {ct.CoverageFactorK.Value.ToString("G29")})";
                    }
                    dto.UncertaintyValues.Add(uncertaintyDisplay);

                    dto.ConformingResults.Add(ct.IsConformingSpec);
                    dto.ConformingUncertaintyResults.Add(ct.IsConformingUncertainty);
                }
                dto.DisplayValue = string.Join(", ", dto.FormattedValues);
                processedTests.Add(dto);
            }
        }

        var receptionId = await _context.Receptions
            .Where(r => r.ControlCodeId == certificate.ControlCodeId)
            .Select(r => r.Id)
            .FirstOrDefaultAsync();

        return new CertificateDetailDto
        {
            Id = certificate.Id,
            ReceptionId = receptionId,
            MaterialName = certificate.ControlCode.Material.Name,
            ControlCode = certificate.ControlCode.Code,
            IsConformingSpec = certificate.IsConformingSpec,
            IsConformingUncertainty = certificate.IsConformingUncertainty,
            DateSubmitted = certificate.DateSubmitted,
            DateCancelled = certificate.DateCancelled,
            IsCancelled = certificate.IsCancelled,
            IsSubmitted = certificate.IsSubmitted,
            Status = status,
            HasTestFromCancelledReport = certificate.CertificateTests.Any(ct => ct.Report.IsCancelled),
            
            SpecId = certificate.SpecId,
            MaterialId = certificate.Spec.MaterialId,
            UserSubmittedTag = certificate.UserSubmitted?.Tag,
            UserCancelledTag = certificate.UserCancelled?.Tag,
            CommentsSubmitted = certificate.CommentsSubmitted,
            CommentsCancelled = certificate.CommentsCancelled,
            Tests = processedTests.OrderBy(t => t.MeasurementId).ThenBy(t => t.NrOrd).ToList()
        };
    }

    // POST /certificates/generate
    public async Task<CertificateDetailDto?> GenerateCertificate(GenerateCertificateDto dto)
    {
        if (dto.MaterialId == 0 || dto.ControlCodeId == 0)
        {
            throw new ArgumentException("material_id and control_code_id are required");
        }

        var spec = await _context.Specs
            .Where(s => s.MaterialId == dto.MaterialId && s.IsSubmitted && !s.IsCancelled)
            .OrderByDescending(s => s.Id)
            .FirstOrDefaultAsync();

        if (spec == null) throw new InvalidOperationException("No valid specification found for this material");

        var certificate = new Certificate
        {
            SpecId = spec.Id,
            ControlCodeId = dto.ControlCodeId,
            IsConformingSpec = false, 
            IsConformingUncertainty = true,
            IsSubmitted = false,
            IsCancelled = false,
            UserSubmittedId = dto.UserId,
            DateSubmitted = DateTime.UtcNow
        };

        _context.Certificates.Add(certificate);
        await _context.SaveChangesAsync();

        await CalculateAndSaveCertificateTests(certificate.Id, spec.Id, dto.ControlCodeId);

        // Refetch to return full object
        return await GetCertificate(certificate.Id);
    }

    // PUT /certificates/{id}
    public async Task UpdateCertificate(long id, UpdateCertificateDto dto)
    {
        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) throw new ArgumentException("Certificate not found");

        if (dto.IsConformingSpec.HasValue)
        {
            certificate.IsConformingSpec = dto.IsConformingSpec.Value;
        }
        if (dto.IsConformingUncertainty.HasValue)
        {
            certificate.IsConformingUncertainty = dto.IsConformingUncertainty.Value;
        }
        await _context.SaveChangesAsync();
    }

    // PUT /certificates/{id}/refresh_tests
    public async Task RefreshTests(long id)
    {
        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) throw new ArgumentException("Certificate not found");

        var controlCode = await _context.ControlCodes.FindAsync(certificate.ControlCodeId);
        if (controlCode == null) throw new InvalidOperationException("Control Code not found");

        var latestSpec = await _context.Specs
            .Where(s => s.MaterialId == controlCode.MaterialId && s.IsSubmitted && !s.IsCancelled)
            .OrderByDescending(s => s.Id)
            .FirstOrDefaultAsync();

        if (latestSpec == null) throw new InvalidOperationException("No valid specification found");

        certificate.SpecId = latestSpec.Id;
        certificate.IsConformingSpec = false;
        certificate.IsConformingUncertainty = true;
        await _context.SaveChangesAsync();

        await CalculateAndSaveCertificateTests(id, latestSpec.Id, certificate.ControlCodeId);
    }

    // GET /certificates/{id}/analyze_results
    public async Task<CertificateAnalysisDto> AnalyzeResults(long id)
    {
        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) throw new ArgumentException("Certificate not found");

        var nonConformingSpecCount = await _context.CertificateTests.CountAsync(ct => ct.CertificateId == id && !ct.IsConformingSpec);
        var nonConformingUncertaintyCount = await _context.CertificateTests.CountAsync(ct => ct.CertificateId == id && !ct.IsConformingUncertainty);

        var specTests = await _context.SpecTests.Where(st => st.SpecId == certificate.SpecId).ToListAsync();
        var mandatoryTestIds = specTests.Where(st => st.TestFrequency > 0).Select(st => st.TestId).ToHashSet();

        var certTestIds = await _context.CertificateTests
            .Where(ct => ct.CertificateId == id)
            .Select(ct => ct.TestId)
            .ToListAsync();
        var certTestIdsSet = new HashSet<long>(certTestIds);

        var missingTestIds = mandatoryTestIds.Where(tid => !certTestIdsSet.Contains(tid)).ToList();

        string analysisResult;
        bool isConformingSpec = nonConformingSpecCount == 0 && missingTestIds.Count == 0;
        bool isConformingUncertainty = nonConformingUncertaintyCount == 0;

        if (isConformingSpec && isConformingUncertainty)
        {
            analysisResult = "All testing results are according to specification";
        }
        else if (isConformingSpec && !isConformingUncertainty)
        {
            analysisResult = "Testing results are conforming, but measurement uncertainty boundaries are inconclusive";
        }
        else
        {
            analysisResult = $"{nonConformingSpecCount} of testing results are out of specification";
            if (missingTestIds.Count > 0)
            {
                var missingTests = await _context.Tests
                    .Where(t => missingTestIds.Contains(t.Id))
                    .Select(t => t.Name)
                    .ToListAsync();
                
                analysisResult += "\nMissing tests:\n" + string.Join("\n", missingTests);
            }
        }

        return new CertificateAnalysisDto 
        { 
            AnalysisResult = analysisResult, 
            IsConformingSpec = isConformingSpec,
            IsConformingUncertainty = isConformingUncertainty
        };
    }

    public async Task<CertificateAnalysisDto> AnalyzeInFlightResults(
        long specId, 
        long controlCodeId, 
        List<(long MeasurementId, bool HasForm, long TestId, decimal Value, int Idx, decimal? UncertaintyValue, decimal? CoverageFactorK)> currentReportTestRows)
    {
        var certifiedTestIds = await _context.Tests
            .Where(t => t.ForCertification && !t.IsObsolete)
            .Select(t => t.Id)
            .ToListAsync();

        var specTests = await _context.SpecTests
            .Where(st => st.SpecId == specId && certifiedTestIds.Contains(st.TestId))
            .ToListAsync();
        var specTestsMap = specTests.ToDictionary(st => st.TestId, st => st);

        var gatheredTests = new List<(long TestId, bool IsConformingSpec, bool IsConformingUncertainty)>();

        foreach (var row in currentReportTestRows)
        {
            if (specTestsMap.TryGetValue(row.TestId, out var specTest))
            {
                bool isConformingSpec = false;
                bool isConformingUncertainty = true;
                var condition = specTest.Condition;
                if (!string.IsNullOrEmpty(condition))
                {
                    try
                    {
                        var params_ = new Dictionary<string, decimal> { { "value", row.Value } };
                        var result = QCFormula.Formula.EvaluateFormula(condition, params_);
                        if (result is bool b) isConformingSpec = b;
                        else if (result is decimal d) isConformingSpec = d != 0;
                    }
                    catch (Exception e)
                    {
                        Console.Error.WriteLine($"Error evaluating formula '{condition}' with value {row.Value}: {e}");
                    }

                    if (row.UncertaintyValue.HasValue && row.CoverageFactorK.HasValue)
                    {
                        var u = row.UncertaintyValue.Value * row.CoverageFactorK.Value;
                        var valMinusU = row.Value - u;
                        var valPlusU = row.Value + u;
                        bool confMinus = false;
                        bool confPlus = false;
                        try
                        {
                            var resMinus = QCFormula.Formula.EvaluateFormula(condition, new Dictionary<string, decimal> { { "value", valMinusU } });
                            if (resMinus is bool bm) confMinus = bm;
                            else if (resMinus is decimal dm) confMinus = dm != 0;

                            var resPlus = QCFormula.Formula.EvaluateFormula(condition, new Dictionary<string, decimal> { { "value", valPlusU } });
                            if (resPlus is bool bp) confPlus = bp;
                            else if (resPlus is decimal dp) confPlus = dp != 0;

                            isConformingUncertainty = confMinus && confPlus;
                        }
                        catch (Exception e)
                        {
                            Console.Error.WriteLine($"Error evaluating uncertainty formula '{condition}' with value {row.Value}: {e}");
                            isConformingUncertainty = false;
                        }
                    }
                    else
                    {
                        isConformingUncertainty = true;
                    }
                }

                gatheredTests.Add((row.TestId, isConformingSpec, isConformingUncertainty));
            }
        }

        // Carry over tests from previous certificate if applicable
        var controlCode = await _context.ControlCodes.FindAsync(controlCodeId);
        if (controlCode != null)
        {
            var previousCert = await _context.Certificates
                .Include(c => c.ControlCode)
                .Where(c => c.ControlCode.MaterialId == controlCode.MaterialId &&
                            c.ControlCodeId < controlCodeId &&
                            c.IsSubmitted &&
                            !c.IsCancelled &&
                            c.IsConformingSpec &&
                            c.IsConformingUncertainty)
                .OrderByDescending(c => c.ControlCodeId)
                .FirstOrDefaultAsync();

            if (previousCert != null)
            {
                var previousCertTests = await _context.CertificateTests
                    .Where(ct => ct.CertificateId == previousCert.Id)
                    .ToListAsync();

                var currentTestIds = new HashSet<long>(gatheredTests.Select(t => t.TestId));

                foreach (var prevTest in previousCertTests)
                {
                    if (specTestsMap.TryGetValue(prevTest.TestId, out var specTestInfo))
                    {
                        if (!currentTestIds.Contains(prevTest.TestId) && (prevTest.TestCount + 1) <= specTestInfo.TestFrequency)
                        {
                            gatheredTests.Add((prevTest.TestId, prevTest.IsConformingSpec, prevTest.IsConformingUncertainty));
                        }
                    }
                }
            }
        }

        int nonConformingSpecCount = gatheredTests.Count(t => !t.IsConformingSpec);
        int nonConformingUncertaintyCount = gatheredTests.Count(t => !t.IsConformingUncertainty);

        var mandatoryTestIds = specTests.Where(st => st.TestFrequency > 0).Select(st => st.TestId).ToHashSet();
        var certTestIdsSet = new HashSet<long>(gatheredTests.Select(t => t.TestId));
        var missingTestIds = mandatoryTestIds.Where(tid => !certTestIdsSet.Contains(tid)).ToList();

        string analysisResult;
        bool isConformingSpecOverall = nonConformingSpecCount == 0 && missingTestIds.Count == 0;
        bool isConformingUncertaintyOverall = nonConformingUncertaintyCount == 0;

        if (isConformingSpecOverall && isConformingUncertaintyOverall)
        {
            analysisResult = "All testing results are according to specification";
        }
        else if (isConformingSpecOverall && !isConformingUncertaintyOverall)
        {
            analysisResult = "Testing results are conforming, but measurement uncertainty boundaries are inconclusive";
        }
        else
        {
            analysisResult = $"{nonConformingSpecCount} of testing results are out of specification";
            if (missingTestIds.Count > 0)
            {
                var missingTests = await _context.Tests
                    .Where(t => missingTestIds.Contains(t.Id))
                    .Select(t => t.Name)
                    .ToListAsync();
                
                analysisResult += "\nMissing tests:\n" + string.Join("\n", missingTests);
            }
        }

        return new CertificateAnalysisDto 
        { 
            AnalysisResult = analysisResult, 
            IsConformingSpec = isConformingSpecOverall,
            IsConformingUncertainty = isConformingUncertaintyOverall
        };
    }

    // GET /certificates/{id}/has_existing
    public async Task<bool> HasExistingValidCertificates(long id)
    {
        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) return false;

        return await _context.Certificates
            .AnyAsync(c => c.Id != id && c.ControlCodeId == certificate.ControlCodeId && c.IsSubmitted && !c.IsCancelled);
    }

    // PUT /certificates/{id}/submit
    public async Task SubmitCertificate(long id, CertificateActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("user_id is required");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var certificate = await _context.Certificates.FindAsync(id);
            if (certificate == null) throw new ArgumentException("Certificate not found");

            var existingValidCerts = await _context.Certificates
                .Where(c => c.Id != id && c.ControlCodeId == certificate.ControlCodeId && c.IsSubmitted && !c.IsCancelled)
                .OrderByDescending(c => c.Id)
                .ToListAsync();

            if (existingValidCerts.Count > 0)
            {
                certificate.CertificateReplacedId = existingValidCerts[0].Id;
            }

            certificate.IsSubmitted = true;
            certificate.UserSubmittedId = dto.UserId;
            certificate.DateSubmitted = DateTime.UtcNow;
            certificate.CommentsSubmitted = dto.CommentsSubmitted;

            // Re-calculate conformance before final submission
            var analysis = await AnalyzeResults(id);
            certificate.IsConformingSpec = analysis.IsConformingSpec;
            certificate.IsConformingUncertainty = analysis.IsConformingUncertainty;

            await _context.SaveChangesAsync();

            foreach (var oldCert in existingValidCerts)
            {
                oldCert.IsCancelled = true;
                oldCert.UserCancelledId = dto.UserId;
                oldCert.DateCancelled = DateTime.UtcNow;
                oldCert.CommentsCancelled = $"Replaced by new certificate #{certificate.Id}";
            }

            await _context.SaveChangesAsync();

            foreach (var oldCert in existingValidCerts)
            {
                await _signatureService.SignEntityAsync(
                    "certificates",
                    oldCert.Id,
                    dto.UserId,
                    "Cancellation",
                    "127.0.0.1",
                    oldCert.CommentsCancelled,
                    _context);
            }

            await transaction.CommitAsync();

            await _signatureService.SignEntityAsync(
                "certificates",
                id,
                dto.UserId,
                "Approval",
                "127.0.0.1",
                dto.CommentsSubmitted);
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // PUT /certificates/{id}/cancel
    public async Task CancelCertificate(long id, CertificateActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("user_id is required");

        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) throw new ArgumentException("Certificate not found");

        certificate.IsCancelled = true;
        certificate.UserCancelledId = dto.UserId;
        certificate.DateCancelled = DateTime.UtcNow;
        certificate.CommentsCancelled = dto.CommentsCancelled;

        await _context.SaveChangesAsync();

        await _signatureService.SignEntityAsync(
            "certificates",
            id,
            dto.UserId,
            "Cancellation",
            "127.0.0.1",
            dto.CommentsCancelled);
    }

    // DELETE /certificates/{id}
    public async Task DeleteCertificate(long id, long userId)
    {
        if (userId == 0)
        {
            throw new UnauthorizedAccessException("User ID is required.");
        }

        // Verify user is is_qc_pers = true
        var user = await _context.Users.FindAsync(userId);
        if (user == null || !user.IsQcPers)
        {
            throw new UnauthorizedAccessException("User must have QC Personnel (is_qc_pers) privilege to delete certificates.");
        }

        var certificate = await _context.Certificates.FindAsync(id);
        if (certificate == null) throw new ArgumentException("Certificate not found");

        // Verify certificate is Draft (not submitted)
        if (certificate.IsSubmitted)
        {
            throw new InvalidOperationException("Only draft (unsubmitted) quality certificates can be deleted.");
        }

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            // Delete corresponding records in certificate_tests table
            var certTests = await _context.CertificateTests.Where(ct => ct.CertificateId == id).ToListAsync();
            if (certTests.Count > 0)
            {
                _context.CertificateTests.RemoveRange(certTests);
            }

            // Delete corresponding record in certificates table
            _context.Certificates.Remove(certificate);

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // GET /certificates/{id}/pdf
    public async Task<byte[]?> GetCertificatePdf(long id)
    {
        var certDto = await GetCertificate(id);
        if (certDto == null) return null;

        var analysis = await AnalyzeResults(id);

        var baseUrl = Environment.GetEnvironmentVariable("PYTHON_REPORTING_URL") ?? Environment.GetEnvironmentVariable("REPORTING_SERVICE_URL") ?? "http://reporting_pdf:8000";
        baseUrl = baseUrl.Replace("/generate-report", "").TrimEnd('/');
        var reportingUrl = $"{baseUrl}/quality-certificate-pdf";

        // Map tests to report test format expected by Python service
        var reportTests = certDto.Tests.Select(t => new
        {
            measurementId = t.MeasurementId,
            hasForm = t.HasForm,
            nrOrd = t.NrOrd,
            testName = t.TestName,
            typeName = t.TypeName,
            unitName = t.UnitName,
            value = t.DisplayValue,
            formattedValues = t.FormattedValues,
            uncertaintyValues = t.UncertaintyValues,
            testCount = t.TestCount,
            testFrequency = t.TestFrequency,
            noteSpec = t.NoteSpec,
            isConformingSpec = t.IsConformingSpec,
            isConformingUncertainty = t.IsConformingUncertainty,
            conformingResults = t.ConformingResults,
            conformingUncertaintyResults = t.ConformingUncertaintyResults,
            reportId = t.ReportId,
            reportIsCancelled = t.ReportIsCancelled
        }).ToList();

        var reportPayload = new
        {
            report = new
            {
                id = certDto.Id,
                materialName = certDto.MaterialName,
                controlCode = certDto.ControlCode,
                specId = certDto.SpecId,
                isConformingSpec = certDto.IsConformingSpec,
                isConformingUncertainty = certDto.IsConformingUncertainty,
                status = certDto.Status,
                userSubmittedTag = certDto.UserSubmittedTag,
                dateSubmitted = certDto.DateSubmitted?.ToString("yyyy-MM-dd HH:mm:ss"),
                commentsSubmitted = certDto.CommentsSubmitted,
                isSubmitted = certDto.IsSubmitted,
                isCancelled = certDto.IsCancelled,
                dateCancelled = certDto.DateCancelled?.ToString("yyyy-MM-dd HH:mm:ss"),
                userCancelledTag = certDto.UserCancelledTag,
                commentsCancelled = certDto.CommentsCancelled,
                analysisResultMessage = analysis.AnalysisResult,
                tests = reportTests
            }
        };

        using var httpClient = new HttpClient();
        var response = await httpClient.PostAsJsonAsync(reportingUrl, reportPayload);
        if (!response.IsSuccessStatusCode)
        {
            var errContent = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException($"Failed to generate PDF from reporting service: {response.StatusCode} - {errContent}");
        }

        return await response.Content.ReadAsByteArrayAsync();
    }

    public async Task<byte[]?> ExportCertificatesExcel(
        bool isQCPersonnel,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null,
        int? loadedPages = null,
        int pageSize = 15,
        IHttpClientFactory? clientFactory = null)
    {
        var query = _context.Certificates
            .Include(c => c.ControlCode)
                .ThenInclude(cc => cc.Material)
            .Include(c => c.Spec)
            .Where(c => !c.IsCancelled)
            .AsQueryable();

        if (!isQCPersonnel)
        {
            query = query.Where(c => c.IsSubmitted);
        }

        if (materialId.HasValue)
        {
            query = query.Where(c => c.ControlCode.MaterialId == materialId);
        }

        if (submissionYear.HasValue)
        {
            query = query.Where(c => c.DateSubmitted.HasValue && c.DateSubmitted.Value.Year == submissionYear.Value);
        }

        if (submissionMonth.HasValue)
        {
            query = query.Where(c => c.DateSubmitted.HasValue && c.DateSubmitted.Value.Month == submissionMonth.Value);
        }

        var orderedQuery = query.OrderByDescending(c => c.Id);

        List<Certificate> certificates;
        if (loadedPages.HasValue && loadedPages.Value > 0)
        {
            certificates = await orderedQuery.Take(loadedPages.Value * pageSize).ToListAsync();
        }
        else
        {
            certificates = await orderedQuery.ToListAsync();
        }

        if (!certificates.Any())
        {
            // return empty
        }

        // Group certificates by Material, sorted ascending by material name
        var certByMaterial = certificates
            .Where(c => c.ControlCode?.Material != null)
            .GroupBy(c => c.ControlCode!.MaterialId)
            .OrderBy(g => g.First().ControlCode!.Material!.Name);

        var sheets = new List<CertSheetExportDto>();

        foreach (var matGroup in certByMaterial)
        {
            var mat = matGroup.First().ControlCode!.Material!;
            var matName = mat.Name;
            var sheetLabel = matName;
            var sheetTitle = matName;

            var tests = await _context.Materials
                .Where(m => m.Id == mat.Id)
                .SelectMany(m => m.Tests)
                .Include(t => t.Type)
                .Include(t => t.Unit)
                .OrderBy(t => t.NrOrd)
                .ToListAsync();

            var testColumns = tests.Select(t => new CertTestColumnDto
            {
                TestId = t.Id,
                Name = t.Name,
                NrOrd = t.NrOrd
            }).ToList();

            var rows = await BuildCertExportRows(matGroup.ToList(), tests);

            sheets.Add(new CertSheetExportDto
            {
                SheetLabel = sheetLabel,
                SheetTitle = sheetTitle,
                Tests = testColumns,
                Rows = rows
            });
        }

        var payload = new QualityCertificatesExportRequestDto { Sheets = sheets };

        if (clientFactory == null) return null;

        var httpClient = clientFactory.CreateClient();
        var baseUrl = Environment.GetEnvironmentVariable("REPORTING_XL_URL") ?? Environment.GetEnvironmentVariable("PYTHON_REPORTING_URL") ?? Environment.GetEnvironmentVariable("REPORTING_SERVICE_URL") ?? "http://reporting_xl:8000";
        var reportingUrl = $"{baseUrl.TrimEnd('/')}/quality-certificates-excel";

        var response = await httpClient.PostAsJsonAsync(reportingUrl, payload);
        if (!response.IsSuccessStatusCode)
        {
            var err = await response.Content.ReadAsStringAsync();
            throw new InvalidOperationException($"Failed to generate Excel from reporting service: {response.StatusCode} - {err}");
        }

        return await response.Content.ReadAsByteArrayAsync();
    }

    private async Task<List<CertExportRowDto>> BuildCertExportRows(List<Certificate> certificates, List<Test> applicableTests)
    {
        var certIds = certificates.Select(c => c.Id).ToList();
        var certTests = await _context.CertificateTests
            .Include(ct => ct.Measurement)
            .Include(ct => ct.Test)
                .ThenInclude(t => t.TestEnums)
            .Where(ct => certIds.Contains(ct.CertificateId))
            .ToListAsync();

        var resultRows = new List<CertExportRowDto>();

        foreach (var cert in certificates)
        {
            var cTests = certTests.Where(ct => ct.CertificateId == cert.Id).ToList();
            if (!cTests.Any()) continue;

            var measurements = cTests.GroupBy(ct => ct.MeasurementId).ToList();

            string dateSubStr = cert.DateSubmitted.HasValue ? cert.DateSubmitted.Value.ToString("yyyy-MM-dd HH:mm") : string.Empty;
            string controlCode = cert.ControlCode?.Code ?? string.Empty;
            string isConforming = cert.IsConformingSpec ? "Yes" : "No";
            string status = cert.IsCancelled ? "Cancelled" : (cert.IsSubmitted ? "Submitted" : "Draft");

            foreach (var mGroup in measurements)
            {
                long measurementId = mGroup.Key;
                bool hasForm = mGroup.First().Measurement.FormId.HasValue;

                var testValueDtos = new List<CertReportTestValueDto>();

                foreach (var test in applicableTests)
                {
                    var tResults = mGroup.Where(ct => ct.TestId == test.Id).OrderBy(ct => ct.Idx).ToList();
                    var formattedValues = new List<string>();

                    foreach (var ct in tResults)
                    {
                        string displayVal = ct.Value.ToString();
                        if (test.TypeId == 4) // Enum
                        {
                            var intVal = (long)ct.Value;
                            var enumVal = test.TestEnums.FirstOrDefault(e => e.Value == intVal);
                            if (enumVal != null) displayVal = enumVal.Name;
                        }
                        else if (test.TypeId == 3) // Boolean
                        {
                            displayVal = ct.Value == 1 ? "Yes" : "No";
                        }
                        else if (ct.Value % 1 == 0)
                        {
                            displayVal = ct.Value.ToString("F1");
                        }
                        formattedValues.Add(displayVal);
                    }

                    if (!formattedValues.Any())
                    {
                        formattedValues.Add("");
                    }

                    testValueDtos.Add(new CertReportTestValueDto
                    {
                        TestId = test.Id,
                        Values = formattedValues
                    });
                }

                resultRows.Add(new CertExportRowDto
                {
                    CertificateId = cert.Id,
                    ControlCode = controlCode,
                    IsConforming = isConforming,
                    DateSubmitted = dateSubStr,
                    Status = status,
                    MeasurementId = measurementId,
                    HasForm = hasForm,
                    TestValues = testValueDtos
                });
            }
        }

        return resultRows;
    }
}