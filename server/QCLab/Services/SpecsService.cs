using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCFormula;

namespace QCLab.Services;

public class SpecsService : ISpecsService
{
    private readonly QualityControlContext _context;
    private readonly ElectronicSignatureService _signatureService;

    public SpecsService(QualityControlContext context, ElectronicSignatureService signatureService)
    {
        _context = context;
        _signatureService = signatureService;
    }

    // GET /specs
    public async Task<List<SpecDto>> GetAllSpecs(long? userId, bool isQCPersonnel)
    {
        var query = _context.Specs
            .Include(s => s.Material)
            .ThenInclude(m => m.Norm)
            .AsQueryable();

        if (!isQCPersonnel)
        {
            query = query.Where(s => s.IsSubmitted && !s.IsCancelled);
        }

        var specs = await query.OrderByDescending(s => s.Id).ToListAsync();

        var specsList = specs.Select(s => {
            var status = "Draft";
            if (s.IsCancelled) status = "Cancelled";
            else if (s.IsSubmitted) status = "Submitted";

            return new SpecDto
            {
                Id = s.Id,
                MaterialId = s.MaterialId,
                MaterialName = s.Material.Name,
                NormName = s.Material.Norm?.Name,
                DateSubmitted = s.DateSubmitted,
                DateCancelled = s.DateCancelled,
                IsSubmitted = s.IsSubmitted,
                SpecReplacedId = s.SpecReplacedId,
                Status = status
            };
        }).ToList();

        return specsList;
    }

    // GET /specs/{id}
    public async Task<SpecDto?> GetSpec(long id)
    {
        return await GetSpecDto(id);
    }

    // POST /specs
    public async Task<IdDto> CreateSpec(CreateSpecDto dto)
    {
        var spec = new Spec
        {
            MaterialId = dto.MaterialId,
            UserSubmittedId = dto.UserId,
            DateSubmitted = DateTime.UtcNow,
            CommentsSubmitted = dto.CommentsSubmitted,
            IsSubmitted = false, 
            IsCancelled = false
        };

        _context.Specs.Add(spec);
        await _context.SaveChangesAsync();

        return new() { Id = spec.Id };
    }

    // PUT /specs/{id}
    public async Task UpdateSpec(long id, UpdateSpecDto dto)
    {
        var spec = await _context.Specs.FindAsync(id);
        if (spec == null) throw new ArgumentException("Specification not found");

        spec.MaterialId = dto.MaterialId;
        spec.UserSubmittedId = dto.UserId;
        spec.DateSubmitted = DateTime.UtcNow;
        spec.CommentsSubmitted = dto.CommentsSubmitted;

        await _context.SaveChangesAsync();
    }

    // POST /specs/{id}/tests
    public async Task<SpecTestDto> AddSpecTest(long id, CreateSpecTestDto dto)
    {
        ValidateSpecTestCondition(dto.Condition);

        var specTest = new SpecTest
        {
            SpecId = id,
            TestId = dto.TestId,
            Condition = dto.Condition,
            Note = dto.Note,
            UseUncertainty = dto.UseUncertainty,
            TestFrequency = dto.TestFrequency,
            SpecTestEvals = dto.Evals.Select(e => new SpecTestEval
            {
                SpecId = id,
                TestId = dto.TestId,
                Value = e.Value,
                ExpectedResult = e.ExpectedResult,
                Note = e.Note
            }).ToList()
        };

        RecalculateEvaluations(specTest.Condition, specTest.SpecTestEvals.ToList());

        _context.SpecTests.Add(specTest);
        await _context.SaveChangesAsync();

        var test = await _context.Tests.Include(t => t.Unit).FirstOrDefaultAsync(t => t.Id == dto.TestId);

        return new SpecTestDto
        {
            TestId = specTest.TestId,
            TestName = test?.Name ?? "",
            UnitName = test?.Unit?.Name,
            NrOrd = test?.NrOrd ?? 0,
            Condition = specTest.Condition,
            Note = specTest.Note,
            UseUncertainty = specTest.UseUncertainty,
            TestFrequency = specTest.TestFrequency,
            Evals = specTest.SpecTestEvals.Select(e => new SpecTestEvalDto
            {
                Id = e.Id,
                Value = e.Value.GetValueOrDefault(),
                Result = e.Result,
                ExpectedResult = e.ExpectedResult,
                IsMatch = e.IsMatch,
                Note = e.Note
            }).ToList()
        };
    }

    // PUT /specs/{id}/tests/{testId}
    public async Task UpdateSpecTest(long id, long testId, UpdateSpecTestDto dto)
    {
        ValidateSpecTestCondition(dto.Condition);

        var specTest = await _context.SpecTests
            .Include(st => st.SpecTestEvals)
            .FirstOrDefaultAsync(st => st.SpecId == id && st.TestId == testId);
            
        if (specTest == null) throw new ArgumentException("Spec test not found");

        specTest.Condition = dto.Condition;
        specTest.Note = dto.Note;
        specTest.UseUncertainty = dto.UseUncertainty;
        specTest.TestFrequency = dto.TestFrequency;

        // Update evaluations
        _context.SpecTestEvals.RemoveRange(specTest.SpecTestEvals);
        specTest.SpecTestEvals = dto.Evals.Select(e => new SpecTestEval
        {
            SpecId = id,
            TestId = testId,
            Value = e.Value,
            ExpectedResult = e.ExpectedResult,
            Note = e.Note
        }).ToList();

        RecalculateEvaluations(specTest.Condition, specTest.SpecTestEvals.ToList());

        await _context.SaveChangesAsync();
    }

    private void RecalculateEvaluations(string condition, List<SpecTestEval> evals)
    {
        foreach (var eval in evals)
        {
            var parameters = new Dictionary<string, decimal> { { "value", (decimal)eval.Value!.Value } };
            try
            {
                var result = QCFormula.Formula.EvaluateFormula(condition, parameters);
                if (result is decimal d)
                {
                    eval.Result = (decimal)d;
                    eval.IsMatch = ((decimal)d == eval.ExpectedResult);
                }
                else if (result is bool b)
                {
                    eval.Result = b ? 1.0m : 0.0m;
                    eval.IsMatch = ((b ? 1.0m : 0.0m) == eval.ExpectedResult);
                }
                else if (result is long i)
                {
                    eval.Result = (decimal)i;
                    eval.IsMatch = ((decimal)i == eval.ExpectedResult);
                }
                else
                {
                    eval.Result = null;
                    eval.IsMatch = false;
                }
            }
            catch
            {
                eval.Result = null;
                eval.IsMatch = false;
            }
        }
    }

    public async Task ValidateCondition(string condition)
    {
        ValidateSpecTestCondition(condition);
        await Task.CompletedTask;
    }

    private void ValidateSpecTestCondition(string condition)
    {
        if (string.IsNullOrWhiteSpace(condition))
        {
            throw new ArgumentException("Condition is required.");
        }

        try
        {
            var params_ = QCFormula.Formula.ExtractParameters(condition);
            if (params_.Any(p => p != "value"))
            {
                throw new ArgumentException("Invalid condition: only scalar parameter 'value' is allowed.");
            }
        }
        catch (Exception ex) when (ex.Message.Contains("Syntax error") || ex.Message.Contains("Invalid syntax"))
        {
            throw new ArgumentException($"Invalid formula syntax: {ex.Message}");
        }
    }

    // DELETE /specs/{id}/tests/{testId}
    public async Task DeleteSpecTest(long id, long testId)
    {
        var evals = await _context.SpecTestEvals.Where(e => e.SpecId == id && e.TestId == testId).ToListAsync();
        _context.SpecTestEvals.RemoveRange(evals);

        var specTest = await _context.SpecTests.FindAsync(id, testId);
        if (specTest != null)
        {
            _context.SpecTests.Remove(specTest);
            await _context.SaveChangesAsync();
        }
    }

    // DELETE /specs/{id}
    public async Task DeleteSpec(long id)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var evals = await _context.SpecTestEvals.Where(e => e.SpecId == id).ToListAsync();
            _context.SpecTestEvals.RemoveRange(evals);

            var tests = await _context.SpecTests.Where(st => st.SpecId == id).ToListAsync();
            _context.SpecTests.RemoveRange(tests);

            var spec = await _context.Specs.FindAsync(id);
            if (spec != null)
            {
                _context.Specs.Remove(spec);
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

    // PUT /specs/{id}/submit
    public async Task<SpecDto?> SubmitSpec(long id, SpecActionDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var spec = await _context.Specs
                .Include(s => s.SpecTests)
                .Include(s => s.SpecTestEvals)
                .FirstOrDefaultAsync(s => s.Id == id);
            if (spec == null) throw new ArgumentException("Specification not found");

            if (spec.SpecTests == null || !spec.SpecTests.Any())
            {
                throw new InvalidOperationException("Cannot submit specification without tests. Please add at least one test.");
            }

            // Validation: Each test must have at least one evaluation
            foreach (var test in spec.SpecTests)
            {
                if (!test.SpecTestEvals.Any())
                {
                    var testName = await _context.Tests
                        .Where(t => t.Id == test.TestId)
                        .Select(t => t.Name)
                        .FirstOrDefaultAsync();
                    throw new InvalidOperationException($"Cannot submit specification. The test '{testName}' does not have any validation tests (evaluations) defined. Please edit the test and add at least one evaluation.");
                }
            }

            // Validation: All evaluation tests must PASS (IsMatch == true)
            if (spec.SpecTestEvals.Any(e => !e.IsMatch))
            {
                throw new InvalidOperationException("Cannot submit specification. All validation tests must PASS. Please review the 'Validation Results' table and correct the specification conditions or evaluation values.");
            }

            // Prevent submission if any test is not for certification
            var specTestIds = spec.SpecTests.Select(st => st.TestId).ToList();
            var certifiedTestIds = await _context.Tests
                .Where(t => t.ForCertification && specTestIds.Contains(t.Id) && !t.IsObsolete)
                .Select(t => t.Id)
                .ToListAsync();

            if (specTestIds.Count > certifiedTestIds.Count)
            {
                var nonCertifiedIds = specTestIds.Except(certifiedTestIds).ToList();
                var nonCertifiedNames = await _context.Tests
                    .Where(t => nonCertifiedIds.Contains(t.Id))
                    .Select(t => t.Name)
                    .ToListAsync();
                
                throw new InvalidOperationException($"Cannot submit specification. The following tests are not configured for certification: {string.Join(", ", nonCertifiedNames)}. Please ensure all tests are performed in a qualified environment before submission.");
            }

            var existingSpecs = await _context.Specs
                .Where(s => s.MaterialId == spec.MaterialId && s.IsSubmitted && !s.IsCancelled && s.Id != id)
                .ToListAsync();

            foreach (var existing in existingSpecs)
            {
                existing.IsCancelled = true;
                existing.UserCancelledId = dto.UserId;
                existing.DateCancelled = DateTime.UtcNow;
                existing.CommentsCancelled = $"Replaced by new spec #{id}";
            }

            spec.IsSubmitted = true;
            spec.UserSubmittedId = dto.UserId;
            spec.DateSubmitted = DateTime.UtcNow;
            spec.CommentsSubmitted = dto.CommentsSubmitted;
            spec.SpecReplacedId = existingSpecs.FirstOrDefault()?.Id;

            await _context.SaveChangesAsync();

            foreach (var existing in existingSpecs)
            {
                await _signatureService.SignEntityAsync(
                    "specs",
                    existing.Id,
                    dto.UserId,
                    "Cancellation",
                    "127.0.0.1",
                    existing.CommentsCancelled,
                    _context);
            }

            await transaction.CommitAsync();

            await _signatureService.SignEntityAsync(
                "specs",
                id,
                dto.UserId,
                "Approval",
                "127.0.0.1",
                dto.CommentsSubmitted);

            return await GetSpecDto(id);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    // PUT /specs/{id}/cancel
    public async Task CancelSpec(long id, SpecActionDto dto)
    {
        var spec = await _context.Specs.FindAsync(id);
        if (spec == null) throw new ArgumentException("Specification not found");

        spec.IsCancelled = true;
        spec.UserCancelledId = dto.UserId;
        spec.DateCancelled = DateTime.UtcNow;
        spec.CommentsCancelled = dto.CommentsCancelled;

        await _context.SaveChangesAsync();

        await _signatureService.SignEntityAsync(
            "specs",
            id,
            dto.UserId,
            "Cancellation",
            "127.0.0.1",
            dto.CommentsCancelled);
    }

    // POST /specs/{id}/duplicate
    public async Task<IdDto> DuplicateSpec(long id, SpecActionDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var originalSpec = await _context.Specs.FindAsync(id);
            if (originalSpec == null) throw new ArgumentException("Specification not found");

            var newSpec = new Spec
            {
                MaterialId = originalSpec.MaterialId,
                UserSubmittedId = dto.UserId,
                DateSubmitted = DateTime.UtcNow,
                CommentsSubmitted = $"Duplicated from spec #{id}",
                IsSubmitted = false,
                IsCancelled = false
            };

            _context.Specs.Add(newSpec);
            await _context.SaveChangesAsync();

            var originalTests = await _context.SpecTests.Where(st => st.SpecId == id).ToListAsync();
            foreach (var test in originalTests)
            {
                var newTest = new SpecTest
                {
                    SpecId = newSpec.Id,
                    TestId = test.TestId,
                    Condition = test.Condition,
                    Note = test.Note,
                    UseUncertainty = test.UseUncertainty,
                    TestFrequency = test.TestFrequency
                };
                _context.SpecTests.Add(newTest);

                var originalEvals = await _context.SpecTestEvals
                    .Where(e => e.SpecId == id && e.TestId == test.TestId)
                    .ToListAsync();
                
                foreach (var eval in originalEvals)
                {
                    _context.SpecTestEvals.Add(new SpecTestEval
                    {
                        SpecId = newSpec.Id,
                        TestId = test.TestId,
                        Value = eval.Value,
                        Result = eval.Result,
                        ExpectedResult = eval.ExpectedResult,
                        IsMatch = eval.IsMatch,
                        Note = eval.Note
                    });
                }
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            return new() { Id = newSpec.Id };
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            throw ex;
        }
    }

    private async Task<SpecDto?> GetSpecDto(long id)
    {
        var spec = await _context.Specs
            .Include(s => s.UserSubmitted)
            .Include(s => s.UserCancelled)
            .Include(s => s.SpecTests)
            .ThenInclude(st => st.Test)
            .ThenInclude(t => t.Unit)
            .Include(s => s.SpecTests)
            .ThenInclude(st => st.SpecTestEvals)
            .Include(s => s.Material)
            .ThenInclude(m => m.Norm)
            .FirstOrDefaultAsync(s => s.Id == id);

        if (spec == null) return null;

        var applicableTests = await _context.Materials
            .Where(m => m.Id == spec.MaterialId)
            .SelectMany(m => m.Tests)
            .Select(t => t.Id)
            .ToListAsync();

        var certifiedTests = await _context.Tests
            .Where(t => t.ForCertification && applicableTests.Contains(t.Id) && !t.IsObsolete)
            .Select(t => t.Id)
            .ToListAsync();

        var status = "Draft";
        if (spec.IsCancelled) status = "Cancelled";
        else if (spec.IsSubmitted) status = "Submitted";

        return new SpecDto
        {
            Id = spec.Id,
            MaterialId = spec.MaterialId,
            MaterialName = spec.Material.Name,
            NormName = spec.Material.Norm?.Name,
            DateSubmitted = spec.DateSubmitted,
            DateCancelled = spec.DateCancelled,
            IsSubmitted = spec.IsSubmitted,
            Status = status,
            UserSubmittedTag = spec.UserSubmitted?.Tag,
            UserCancelledTag = spec.UserCancelled?.Tag,
            CommentsSubmitted = spec.CommentsSubmitted,
            CommentsCancelled = spec.CommentsCancelled,
            ApplicableTests = applicableTests,
            CertifiedTests = certifiedTests,
            Tests = spec.SpecTests.Select(st => new SpecTestDto
            {
                TestId = st.TestId,
                TestName = st.Test.Name,
                UnitName = st.Test.Unit?.Name,
                NrOrd = st.Test.NrOrd,
                Condition = st.Condition,
                Note = st.Note,
                UseUncertainty = st.UseUncertainty,
                TestFrequency = st.TestFrequency,
                Evals = st.SpecTestEvals.Select(e => new SpecTestEvalDto
                {
                    Id = e.Id,
                    Value = e.Value.GetValueOrDefault(),
                    Result = e.Result,
                    ExpectedResult = e.ExpectedResult,
                    IsMatch = e.IsMatch,
                    Note = e.Note
                }).ToList()
            }).ToList()
        };
    }

    // GET /specs/{id}/pdf
    public async Task<byte[]?> GetSpecPdf(long id)
    {
        var spec = await _context.Specs
            .Include(s => s.UserSubmitted)
            .Include(s => s.UserCancelled)
            .Include(s => s.Material)
            .ThenInclude(m => m.Norm)
            .Include(s => s.SpecTests)
            .ThenInclude(st => st.Test)
            .ThenInclude(t => t.Unit)
            .FirstOrDefaultAsync(s => s.Id == id);

        var specDto = await GetSpec(id);
        if (specDto == null || spec == null) return null;

        var baseUrl = Environment.GetEnvironmentVariable("PYTHON_REPORTING_URL") ?? Environment.GetEnvironmentVariable("REPORTING_SERVICE_URL") ?? "http://reporting_pdf:8000";
        baseUrl = baseUrl.Replace("/generate-report", "").TrimEnd('/');
        var reportingUrl = $"{baseUrl}/specification-pdf";

        if (!reportingUrl.EndsWith("/specification-pdf"))
        {
            reportingUrl = reportingUrl.TrimEnd('/') + "/specification-pdf";
        }

        var reportPayload = new
        {
            report = new
            {
                id = specDto.Id,
                materialName = specDto.MaterialName,
                normName = specDto.NormName,
                status = specDto.Status,
                userSubmittedTag = specDto.UserSubmittedTag,
                dateSubmitted = specDto.DateSubmitted?.ToString("yyyy-MM-dd HH:mm:ss"),
                commentsSubmitted = specDto.CommentsSubmitted,
                isSubmitted = specDto.IsSubmitted,
                isCancelled = spec.IsCancelled,
                dateCancelled = specDto.DateCancelled?.ToString("yyyy-MM-dd HH:mm:ss"),
                userCancelledTag = specDto.UserCancelledTag,
                commentsCancelled = specDto.CommentsCancelled,
                tests = specDto.Tests?.Select(t => new
                {
                    testName = t.TestName,
                    unitName = t.UnitName,
                    condition = t.Condition,
                    note = t.Note,
                    useUncertainty = t.UseUncertainty,
                    testFrequency = t.TestFrequency
                }).ToList()
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
}