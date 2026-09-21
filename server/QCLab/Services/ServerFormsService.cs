using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCFormula;

namespace QCLab.Services;

public class ServerFormsService : IFormsService
{
    private readonly QualityControlContext _context;
    private readonly ElectronicSignatureService _signatureService;
    private readonly IFormEvalsService _evalsService;

    public ServerFormsService(QualityControlContext context, IFormEvalsService evalsService, ElectronicSignatureService signatureService)
    {
        _context = context;
        _evalsService = evalsService;
        _signatureService = signatureService;
    }

    // GET /forms
    public async Task<List<FormDto>> GetAllForms()
    {
        var forms = await _context.Forms
            .Include(f => f.FormGroup)
            .Include(f => f.FormParams)
            .Select(f => new FormDto
            {
                Id = f.Id,
                Name = $"{f.FormGroup.Name} ({f.Version})",
                CustomNav = f.CustomNav,
                IsCustomized = f.IsCustomized,
                IsCancelled = f.IsCancelled,
                IsSubmitted = f.IsSubmitted,
                IsValidated = f.IsValidated,
                FormParams = f.FormParams.OrderBy(fp => fp.NrOrd).Select(fp => new FormParamSimpleDto
                {
                    TestId = fp.TestId,
                    IsCalculated = fp.IsCalculated,
                    CodeRelatedArrays = fp.CodeRelatedArrays,
                    IsRequired = fp.IsRequired,
                    DefaultValue = fp.DefaultValue,
                    NrOrd = fp.NrOrd,
                    ConditionNote = fp.ConditionNote
                }).ToList()
            })
            .ToListAsync();

        return forms;
    }

    // GET /forms/{id}
    public async Task<FormDetailDto?> GetForm(long id)
    {
        var form = await _context.Forms
            .Include(f => f.FormGroup)
            .Include(f => f.UserSubmitted)
            .Include(f => f.UserValidated)
            .Include(f => f.UserCancelled)
            .FirstOrDefaultAsync(f => f.Id == id);

        if (form == null) return null;

        return new FormDetailDto
        {
            Id = form.Id,
            FormGroupId = form.FormGroupId,
            Version = form.Version,
            CustomNav = form.CustomNav,
            IsCustomized = form.IsCustomized,
            IsSubmitted = form.IsSubmitted,
            UserSubmittedId = form.UserSubmittedId,
            UserSubmittedTag = form.UserSubmitted?.Tag,
            DateSubmitted = form.DateSubmitted,
            CommentsSubmitted = form.CommentsSubmitted,
            IsValidated = form.IsValidated,
            UserValidatedTag = form.UserValidated?.Tag,
            DateValidated = form.DateValidated,
            CommentsValidated = form.CommentsValidated,
            IsCancelled = form.IsCancelled,
            UserCancelledTag = form.UserCancelled?.Tag,
            DateCancelled = form.DateCancelled,
            CommentsCancelled = form.CommentsCancelled,
            Name = $"{form.FormGroup.Name} ({form.Version})"
        };
    }

    // POST /forms
    public async Task<IdDto> CreateForm(CreateFormDto dto)
    {
        var form = new Form
        {
            FormGroupId = dto.FormGroupId,
            Version = dto.Version,
            CustomNav = dto.CustomNav,
            IsCustomized = dto.IsCustomized,
            UserSubmittedId = dto.SubmittedUserId,
            DateSubmitted = dto.SubmittedDate
        };

        _context.Forms.Add(form);
        await SaveChangesWithDetailedException();

        return new() { Id = form.Id };
    }

    // PUT /forms/{id}
    public async Task UpdateForm(long id, UpdateFormDto dto)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (form.IsValidated) throw new InvalidOperationException("Cannot update a validated form.");

        // Ensure IDs are valid to avoid FK failures
        if (dto.FormGroupId > 0)
        {
            form.FormGroupId = dto.FormGroupId;
        }
        
        form.Version = dto.Version;
        form.CustomNav = dto.CustomNav;
        form.IsCustomized = dto.IsCustomized;
        
        if (!form.IsSubmitted && dto.UserId > 0)
        {
            form.UserSubmittedId = dto.UserId;
            form.DateSubmitted = DateTime.UtcNow;
        }

        await SaveChangesWithDetailedException();
    }

    // GET /forms/{id}/params
    public async Task<List<FormParamDto>> GetFormParams(long id)
    {
        var formParams = await _context.FormParams
            .Include(fp => fp.Test)
            .Include(fp => fp.FormConditionEvals)
            .Where(fp => fp.FormId == id)
            .OrderBy(fp => fp.NrOrd)
            .ToListAsync();

        var paramsList = new List<FormParamDto>();

        foreach (var p in formParams)
        {
            var dto = new FormParamDto
            {
                FormId = p.FormId,
                TestId = p.TestId,
                IsCalculated = p.IsCalculated,
                Formula = p.Formula,
                CodeRelatedArrays = p.CodeRelatedArrays,
                IsRequired = p.IsRequired,
                DefaultValue = p.DefaultValue,
                NrOrd = p.NrOrd,
                NrOrdCalc = p.NrOrdCalc,
                Code = p.Test.Code,
                Name = p.Test.Name,
                TypeId = p.Test.TypeId,
                IsArray = p.Test.IsArray,
                HasCondition = p.HasCondition,
                Condition = p.Condition,
                ConditionNote = p.ConditionNote,
                Evals = p.FormConditionEvals.Select(e => new FormConditionEvalDto
                {
                    Id = e.Id,
                    FormId = e.FormId,
                    TestId = e.TestId,
                    Value = e.Value,
                    Result = e.Result,
                    ExpectedResult = e.ExpectedResult,
                    IsMatch = e.IsMatch,
                    Note = e.Note
                }).ToList()
            };

            if (p.IsCalculated && !string.IsNullOrEmpty(p.Formula))
            {
                try
                {
                    var dependencies = QCFormula.Formula.ExtractParameters(p.Formula);
                    dependencies.Sort();
                    var formattedDeps = dependencies.Select(dep => dep.EndsWith("__") ? $"[[{dep.Substring(0, dep.Length - 2)}]]" : $"[{dep}]");
                    dto.Dependencies = string.Join(", ", formattedDeps);
                }
                catch (Exception e)
                {
                    Console.Error.WriteLine($"Could not extract parameters for formula '{p.Formula}': {e}");
                }
            }
            paramsList.Add(dto);
        }

        return paramsList;
    }

    // PUT /forms/{id}/params/reorder
    public async Task ReorderFormParams(long id, List<ReorderFormParamDto> reorderedParams)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            foreach (var param in reorderedParams)
            {
                var formParam = await _context.FormParams.FindAsync(id, param.TestId);
                if (formParam != null)
                {
                    formParam.NrOrd = param.NrOrd;
                }
            }
            await SaveChangesWithDetailedException();
            await UpdateCalculationOrder(id);
            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // PUT /forms/{id}/params/batch-update
    public async Task BatchUpdateFormParams(long id, List<BatchUpdateFormParamDto> paramsData)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (form.IsValidated) throw new InvalidOperationException("Cannot modify a validated form.");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var existingParams = await _context.FormParams.Where(fp => fp.FormId == id).Select(fp => fp.TestId).ToListAsync();
            var receivedTestIds = paramsData.Where(p => p.TestId != 0).Select(p => p.TestId).ToHashSet();

            var paramsToDelete = existingParams.Where(tid => !receivedTestIds.Contains(tid)).ToList();
            if (paramsToDelete.Count > 0)
            {
                var toDelete = await _context.FormParams.Where(fp => fp.FormId == id && paramsToDelete.Contains(fp.TestId)).ToListAsync();
                _context.FormParams.RemoveRange(toDelete);

                var evalsToDelete = await _context.FormConditionEvals.Where(e => e.FormId == id && paramsToDelete.Contains(e.TestId)).ToListAsync();
                _context.FormConditionEvals.RemoveRange(evalsToDelete);
            }

            foreach (var param in paramsData)
            {
                if (param.TestId == 0) continue;

                var existing = await _context.FormParams
                    .Include(fp => fp.FormConditionEvals)
                    .FirstOrDefaultAsync(fp => fp.FormId == id && fp.TestId == param.TestId);

                if (existing != null)
                {
                    existing.IsCalculated = param.IsCalculated;
                    existing.Formula = param.Formula;
                    existing.CodeRelatedArrays = param.CodeRelatedArrays;
                    existing.IsRequired = param.IsRequired;
                    existing.DefaultValue = param.DefaultValue;
                    existing.NrOrd = param.NrOrd;
                    existing.NrOrdCalc = 0;
                    SetFormulaDependencies(existing);

                    existing.HasCondition = param.HasCondition;
                    if (param.HasCondition)
                    {
                        if (string.IsNullOrWhiteSpace(param.Condition))
                        {
                            throw new ArgumentException("Condition is required when Has Condition is enabled.");
                        }
                        ValidateSpecTestCondition(param.Condition);

                        existing.Condition = param.Condition;
                        existing.ConditionNote = param.ConditionNote;

                        _context.FormConditionEvals.RemoveRange(existing.FormConditionEvals);
                        existing.FormConditionEvals = param.Evals.Select(e => new FormConditionEval
                        {
                            FormId = id,
                            TestId = param.TestId,
                            Value = e.Value,
                            ExpectedResult = e.ExpectedResult,
                            Note = e.Note
                        }).ToList();

                        RecalculateFormConditionEvaluations(existing.Condition, existing.FormConditionEvals.ToList());
                    }
                    else
                    {
                        existing.Condition = null;
                        existing.ConditionNote = null;
                        _context.FormConditionEvals.RemoveRange(existing.FormConditionEvals);
                        existing.FormConditionEvals.Clear();
                    }
                }
                else
                {
                    var newParam = new FormParam
                    {
                        FormId = id,
                        TestId = param.TestId,
                        IsCalculated = param.IsCalculated,
                        Formula = param.Formula,
                        CodeRelatedArrays = param.CodeRelatedArrays,
                        IsRequired = param.IsRequired,
                        DefaultValue = param.DefaultValue,
                        NrOrd = param.NrOrd,
                        NrOrdCalc = 0,
                        HasCondition = param.HasCondition,
                        Condition = param.HasCondition ? param.Condition : null,
                        ConditionNote = param.HasCondition ? param.ConditionNote : null
                    };
                    SetFormulaDependencies(newParam);

                    if (param.HasCondition)
                    {
                        if (string.IsNullOrWhiteSpace(param.Condition))
                        {
                            throw new ArgumentException("Condition is required when Has Condition is enabled.");
                        }
                        ValidateSpecTestCondition(param.Condition);

                        newParam.FormConditionEvals = param.Evals.Select(e => new FormConditionEval
                        {
                            FormId = id,
                            TestId = param.TestId,
                            Value = e.Value,
                            ExpectedResult = e.ExpectedResult,
                            Note = e.Note
                        }).ToList();

                        RecalculateFormConditionEvaluations(newParam.Condition, newParam.FormConditionEvals.ToList());
                    }

                    _context.FormParams.Add(newParam);
                }
            }

            await SaveChangesWithDetailedException();
            await UpdateCalculationOrder(id);

            // After batch update, if the form is submitted, we must ensure it's still structurally valid
            if (form.IsSubmitted)
            {
                await InternalValidateFormStructure(id);
                await RecalculateAllEvals(id);
            }

            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // POST /forms/{id}/params
    public async Task<IdDto> AddFormParam(long id, CreateFormParamDto dto)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (form.IsValidated) throw new InvalidOperationException("Cannot modify a validated form.");

        var formParam = new FormParam
        {
            FormId = id,
            TestId = dto.TestId,
            IsCalculated = dto.IsCalculated,
            Formula = dto.Formula,
            CodeRelatedArrays = dto.CodeRelatedArrays,
            IsRequired = dto.IsRequired,
            DefaultValue = dto.DefaultValue,
            NrOrd = dto.NrOrd,
            NrOrdCalc = dto.NrOrdCalc,
            HasCondition = dto.HasCondition,
            Condition = dto.HasCondition ? dto.Condition : null,
            ConditionNote = dto.HasCondition ? dto.ConditionNote : null
        };
        SetFormulaDependencies(formParam);

        if (dto.HasCondition)
        {
            if (string.IsNullOrWhiteSpace(dto.Condition))
            {
                throw new ArgumentException("Condition is required when Has Condition is enabled.");
            }
            ValidateSpecTestCondition(dto.Condition);

            formParam.FormConditionEvals = dto.Evals.Select(e => new FormConditionEval
            {
                FormId = id,
                TestId = dto.TestId,
                Value = e.Value,
                ExpectedResult = e.ExpectedResult,
                Note = e.Note
            }).ToList();

            RecalculateFormConditionEvaluations(formParam.Condition, formParam.FormConditionEvals.ToList());
        }

        _context.FormParams.Add(formParam);
        await SaveChangesWithDetailedException();
        await UpdateCalculationOrder(id);

        if (form.IsSubmitted)
        {
            try 
            { 
                await InternalValidateFormStructure(id); 
                await RecalculateAllEvals(id);
            }
            catch 
            { 
                _context.FormParams.Remove(formParam); 
                var evals = await _context.FormConditionEvals.Where(e => e.FormId == id && e.TestId == dto.TestId).ToListAsync();
                _context.FormConditionEvals.RemoveRange(evals);
                await _context.SaveChangesAsync(); 
                throw; 
            }
        }

        return new() { Id = formParam.TestId };
    }

    // PUT /forms/{id}/params/{testId}
    public async Task UpdateFormParam(long id, long testId, UpdateFormParamDto dto)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (form.IsValidated) throw new InvalidOperationException("Cannot modify a validated form.");

        var formParam = await _context.FormParams
            .Include(fp => fp.FormConditionEvals)
            .FirstOrDefaultAsync(fp => fp.FormId == id && fp.TestId == testId);
        if (formParam == null) throw new ArgumentException("Form parameter not found");

        var oldIsCalculated = formParam.IsCalculated;
        var oldFormula = formParam.Formula;
        var oldHasCondition = formParam.HasCondition;
        var oldCondition = formParam.Condition;
        var oldConditionNote = formParam.ConditionNote;

        formParam.IsCalculated = dto.IsCalculated;
        formParam.Formula = dto.Formula;
        formParam.CodeRelatedArrays = dto.CodeRelatedArrays;
        formParam.IsRequired = dto.IsRequired;
        formParam.DefaultValue = dto.DefaultValue;
        formParam.NrOrd = dto.NrOrd;
        formParam.NrOrdCalc = dto.NrOrdCalc;

        formParam.HasCondition = dto.HasCondition;
        if (dto.HasCondition)
        {
            if (string.IsNullOrWhiteSpace(dto.Condition))
            {
                throw new ArgumentException("Condition is required when Has Condition is enabled.");
            }
            ValidateSpecTestCondition(dto.Condition);

            formParam.Condition = dto.Condition;
            formParam.ConditionNote = dto.ConditionNote;

            _context.FormConditionEvals.RemoveRange(formParam.FormConditionEvals);
            formParam.FormConditionEvals = dto.Evals.Select(e => new FormConditionEval
            {
                FormId = id,
                TestId = testId,
                Value = e.Value,
                ExpectedResult = e.ExpectedResult,
                Note = e.Note
            }).ToList();

            RecalculateFormConditionEvaluations(formParam.Condition, formParam.FormConditionEvals.ToList());
        }
        else
        {
            formParam.Condition = null;
            formParam.ConditionNote = null;
            _context.FormConditionEvals.RemoveRange(formParam.FormConditionEvals);
            formParam.FormConditionEvals.Clear();
        }

        SetFormulaDependencies(formParam);

        await SaveChangesWithDetailedException();
        await UpdateCalculationOrder(id);

        if (form.IsSubmitted)
        {
            try 
            { 
                await InternalValidateFormStructure(id); 
                await RecalculateAllEvals(id);
            }
            catch 
            { 
                formParam.IsCalculated = oldIsCalculated; 
                formParam.Formula = oldFormula; 
                formParam.HasCondition = oldHasCondition;
                formParam.Condition = oldCondition;
                formParam.ConditionNote = oldConditionNote;
                await _context.SaveChangesAsync(); 
                throw; 
            }
        }
    }

    private void SetFormulaDependencies(FormParam param)
    {
        if (param.IsCalculated && !string.IsNullOrWhiteSpace(param.Formula))
        {
            try
            {
                var dependencies = QCFormula.Formula.ExtractParameters(param.Formula);
                var cleanDeps = dependencies.Select(d => d.EndsWith("__") ? d.Substring(0, d.Length - 2) : d);
                param.FormulaDependencies = string.Join(",", cleanDeps);
            }
            catch
            {
                param.FormulaDependencies = "";
            }
        }
        else
        {
            param.FormulaDependencies = "";
        }
    }

    private async Task RecalculateAllEvals(long formId)
    {
        var evals = await _context.FormEvals.Where(e => e.FormId == formId).ToListAsync();
        foreach (var ev in evals)
        {
            await _evalsService.CalculateFormEval(ev.Id);
        }
    }

    private async Task UpdateCalculationOrder(long formId)
    {
        var formParams = await _context.FormParams
            .Include(fp => fp.Test)
            .Where(fp => fp.FormId == formId)
            .OrderBy(fp => fp.NrOrd)
            .ToListAsync();

        string GetParameterKeyName(string code, bool isArray) => code + (isArray ? "__" : "");

        var testIdToCode = formParams.ToDictionary(p => p.TestId, p => GetParameterKeyName(p.Test.Code, p.Test.IsArray));
        var orderedCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToList();

        var dependencies = new Dictionary<string, List<string>>();
        foreach (var p in formParams)
        {
            var key = GetParameterKeyName(p.Test.Code, p.Test.IsArray);
            dependencies[key] = p.IsCalculated && !string.IsNullOrEmpty(p.Formula)
                ? QCFormula.Formula.ExtractParameters(p.Formula)
                : new List<string>();
        }

        var reorderedCodes = QCFormula.Formula.ReorderParametersByDependencies(orderedCodes, dependencies);
        var codeToTestId = testIdToCode.ToDictionary(x => x.Value, x => x.Key);

        for (int i = 0; i < reorderedCodes.Count; i++)
        {
            var code = reorderedCodes[i];
            if (codeToTestId.TryGetValue(code, out long testId))
            {
                var fp = await _context.FormParams.FindAsync(formId, testId);
                if (fp != null)
                {
                    fp.NrOrdCalc = i + 1;
                }
            }
        }
        await _context.SaveChangesAsync();
    }

    private async Task InternalValidateFormStructure(long formId)
    {
        var formParams = await _context.FormParams
            .Include(fp => fp.Test)
            .Include(fp => fp.FormConditionEvals)
            .Where(fp => fp.FormId == formId)
            .OrderBy(fp => fp.NrOrd)
            .ToListAsync();

        if (!formParams.Any(p => !p.Test.IsParam))
        {
            throw new Exception("Form must contain at least one test (!).");
        }

        string GetParameterKeyName(string code, bool isArray) => code + (isArray ? "__" : "");
        var availableCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToHashSet();

        foreach (var p in formParams)
        {
            if (p.IsCalculated && !string.IsNullOrEmpty(p.Formula))
            {
                List<string> formulaParams;
                try { formulaParams = QCFormula.Formula.ExtractParameters(p.Formula); }
                catch (Exception e) { throw new Exception($"Syntax error in formula for '{p.Test.Code}': {e.Message}"); }

                foreach (var fParam in formulaParams)
                {
                    if (!availableCodes.Contains(fParam))
                    {
                        var cleanCode = fParam.EndsWith("__") ? fParam.Substring(0, fParam.Length - 2) : fParam;
                        var expectedType = fParam.EndsWith("__") ? "array [[]]" : "scalar []";
                        throw new Exception($"Formula for '{p.Test.Code}' references '{cleanCode}' as {expectedType}, but it's not found in the form.");
                    }
                }

                var returnType = QCFormula.Formula.GetFormulaReturnType(p.Formula);
                if (!p.Test.IsArray && returnType == FormulaReturnType.Array)
                    throw new Exception($"Calculated field '{p.Test.Code}' is scalar but returns an array.");
                if (p.Test.IsArray && returnType == FormulaReturnType.Scalar)
                    throw new Exception($"Calculated field '{p.Test.Code}' is an array but returns a scalar.");
            }

            if (p.HasCondition)
            {
                if (string.IsNullOrWhiteSpace(p.Condition))
                {
                    throw new Exception($"Condition is required for '{p.Test.Code}' because Has Condition is enabled.");
                }

                try
                {
                    var condParams = QCFormula.Formula.ExtractParameters(p.Condition);
                    if (condParams.Any(cp => cp != "value"))
                    {
                        throw new Exception($"Invalid condition for '{p.Test.Code}': only scalar parameter 'value' is allowed.");
                    }
                }
                catch (Exception ex)
                {
                    throw new Exception($"Invalid condition syntax for '{p.Test.Code}': {ex.Message}");
                }

                if (p.FormConditionEvals == null || !p.FormConditionEvals.Any())
                {
                    throw new Exception($"The parameter '{p.Test.Code}' does not have any verification tests (evaluations) defined. Please edit the parameter and add at least one evaluation.");
                }
            }
        }

        // Check for circular references
        try
        {
            var orderedCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToList();
            var dependencies = new Dictionary<string, List<string>>();
            foreach (var p in formParams)
            {
                var key = GetParameterKeyName(p.Test.Code, p.Test.IsArray);
                dependencies[key] = p.IsCalculated && !string.IsNullOrEmpty(p.Formula) 
                    ? QCFormula.Formula.ExtractParameters(p.Formula) 
                    : new List<string>();
            }
            QCFormula.Formula.ReorderParametersByDependencies(orderedCodes, dependencies);
        }
        catch (Exception e) { throw new Exception($"Structural error: {e.Message}"); }
    }

    // DELETE /forms/{id}/params/{testId}
    public async Task DeleteFormParam(long id, long testId)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");

        var formParam = await _context.FormParams.Include(p => p.Test).FirstOrDefaultAsync(p => p.FormId == id && p.TestId == testId);
        if (formParam == null) return;

        if (form.IsValidated) throw new InvalidOperationException("Cannot delete parameters from a validated form.");

        if (form.IsSubmitted)
        {
            // 1. Cannot delete if it is the last test
            if (!formParam.Test.IsParam)
            {
                var otherTestsCount = await _context.FormParams.CountAsync(fp => fp.FormId == id && fp.TestId != testId && !fp.Test.IsParam);
                if (otherTestsCount == 0)
                {
                    throw new InvalidOperationException("A form must contain at least one test. Cannot delete the last test.");
                }
            }

            // 2. Cannot delete if referenced by other formulas
            var allOtherParams = await _context.FormParams.Where(fp => fp.FormId == id && fp.TestId != testId && fp.IsCalculated && !string.IsNullOrEmpty(fp.Formula)).ToListAsync();
            var searchCode = formParam.Test.IsArray ? $"[[{formParam.Test.Code}]]" : $"[{formParam.Test.Code}]";
            foreach (var other in allOtherParams)
            {
                if (other.Formula!.Contains(searchCode))
                {
                    throw new InvalidOperationException($"Cannot delete '{formParam.Test.Code}' because it is referenced in the formula of '{other.TestId}'.");
                }
            }
        }

        // Cascade delete related records manually for SQLite
        var evalParams = await _context.FormEvalParams.Where(ep => ep.FormId == id && ep.TestId == testId).ToListAsync();
        if (evalParams.Any()) _context.FormEvalParams.RemoveRange(evalParams);

        var measParams = await _context.MeasurementParams.Where(mp => mp.FormId == id && mp.TestId == testId).ToListAsync();
        if (measParams.Any()) _context.MeasurementParams.RemoveRange(measParams);

        var condParams = await _context.FormConditionEvals.Where(ep => ep.FormId == id && ep.TestId == testId).ToListAsync();
        if (condParams.Any()) _context.FormConditionEvals.RemoveRange(condParams);

        _context.FormParams.Remove(formParam);
        await SaveChangesWithDetailedException();
        await UpdateCalculationOrder(id);

        if (form.IsSubmitted)
        {
            await RecalculateAllEvals(id);
        }
    }

    // PUT /forms/{id}/submit
    public async Task SubmitForm(long id, FormActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required for submission");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var formParams = await _context.FormParams
                .Include(fp => fp.Test)
                .Where(fp => fp.FormId == id)
                .OrderBy(fp => fp.NrOrd)
                .ToListAsync();

            // 1. Must contain at least one test
            if (!formParams.Any(p => !p.Test.IsParam))
            {
                throw new Exception("Form must contain at least one test (!).");
            }

            string GetParameterKeyName(string code, bool isArray) => code + (isArray ? "__" : "");

            var testIdToCode = formParams.ToDictionary(p => p.TestId, p => GetParameterKeyName(p.Test.Code, p.Test.IsArray));
            var availableCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToHashSet();
            var orderedCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToList();

            var dependencies = new Dictionary<string, List<string>>();
            foreach (var p in formParams)
            {
                var key = GetParameterKeyName(p.Test.Code, p.Test.IsArray);
                if (p.IsCalculated && !string.IsNullOrEmpty(p.Formula))
                {
                    List<string> formulaParams;
                    try
                    {
                        formulaParams = QCFormula.Formula.ExtractParameters(p.Formula);
                        dependencies[key] = formulaParams;
                    }
                    catch (Exception e)
                    {
                        throw new Exception($"Syntax error in formula for '{p.Test.Code}': {e.Message}");
                    }

                    // 2. All parameters referenced must be present in the form and have correct type
                    foreach (var fParam in formulaParams)
                    {
                        if (!availableCodes.Contains(fParam))
                        {
                            var cleanCode = fParam.EndsWith("__") ? fParam.Substring(0, fParam.Length - 2) : fParam;
                            var expectedType = fParam.EndsWith("__") ? "array [[]]" : "scalar []";
                            throw new Exception($"Formula for '{p.Test.Code}' references '{cleanCode}' as {expectedType}, but it's not found in the form with that type.");
                        }
                    }

                    // 3. Check return type
                    var returnType = QCFormula.Formula.GetFormulaReturnType(p.Formula);
                    if (!p.Test.IsArray && returnType == FormulaReturnType.Array)
                    {
                        throw new Exception($"Calculated field '{p.Test.Code}' is scalar but its formula returns an array.");
                    }
                    if (p.Test.IsArray && returnType == FormulaReturnType.Scalar)
                    {
                        throw new Exception($"Calculated field '{p.Test.Code}' is an array but its formula returns a scalar.");
                    }
                }
                else
                {
                    dependencies[key] = new List<string>();
                }
            }

            var form = await _context.Forms.FindAsync(id);
            if (form != null)
            {
                form.IsSubmitted = true;
                form.UserSubmittedId = dto.UserId;
                form.DateSubmitted = DateTime.UtcNow;
            }

            await SaveChangesWithDetailedException();
            await UpdateCalculationOrder(id);
            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // PUT /forms/{id}/validate
    public async Task ValidateForm(long id, FormActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required for validation");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var form = await _context.Forms.FindAsync(id);
            if (form == null) throw new ArgumentException("Form not found");
            if (!form.IsSubmitted) throw new InvalidOperationException("Form must be submitted before validation");
            if (form.IsValidated) throw new InvalidOperationException("Form already validated");

            // 1. Perform all submission validations again
            await InternalValidateFormStructure(id);

            var formParams = await _context.FormParams
                .Include(p => p.Test)
                .Include(p => p.FormConditionEvals)
                .Where(fp => fp.FormId == id)
                .ToListAsync();

            foreach (var p in formParams)
            {
                if (p.HasCondition && p.FormConditionEvals != null && p.FormConditionEvals.Any(e => !e.IsMatch))
                {
                    throw new Exception($"Validation test failed for '{p.Test.Code}'. All condition verification tests must PASS.");
                }
            }
            
            // Validate: The form should have at least one calculated test ('is_param' = false)
            if (!formParams.Any(p => p.IsCalculated && !p.Test.IsParam))
            {
                throw new Exception("The form should have at least one calculated test (!*).");
            }

            // 2. All tests in 'Test Data for Formula Validation' should be PASS (is_match)
            var evals = await _context.FormEvals.Include(e => e.FormEvalParams).Where(e => e.FormId == id).ToListAsync();
            if (!evals.Any())
            {
                throw new Exception("Form must have at least one validation test case before validation.");
            }

            var calculatedParams = formParams.Where(fp => fp.IsCalculated).ToList();

            foreach (var ev in evals)
            {
                foreach (var cp in calculatedParams)
                {
                    // For arrays, we might have multiple indices, but usually we expect at least the same number of elements as in the input
                    // For simplicity and based on user request, we check if at least index 0 exists or if any element exists for this test
                    var results = ev.FormEvalParams.Where(p => p.TestId == cp.TestId).ToList();
                    
                    if (!results.Any())
                    {
                        throw new Exception($"Validation test case '{ev.Description}' is missing calculated result for '{cp.Test.Code}'. Run 'Save and Calculate' in that test case.");
                    }

                    if (results.Any(r => !r.IsMatch))
                    {
                        throw new Exception($"Validation test case '{ev.Description}' has failing results for '{cp.Test.Code}'. All calculated tests must PASS.");
                    }
                }
            }

            // 3. Check for orphan parameters (is_param = true but not used in any formula)
            var allUsedCodes = new HashSet<string>();
            foreach (var p in formParams.Where(fp => fp.IsCalculated && !string.IsNullOrEmpty(fp.Formula)))
            {
                try
                {
                    var deps = QCFormula.Formula.ExtractParameters(p.Formula);
                    foreach (var d in deps) allUsedCodes.Add(d);
                }
                catch { /* Structural validation already covers syntax errors */ }
            }

            string GetParameterKeyName(string code, bool isArray) => code + (isArray ? "__" : "");
            
            var orphanParams = formParams
                .Where(p => p.Test.IsParam)
                .Where(p => !allUsedCodes.Contains(GetParameterKeyName(p.Test.Code, p.Test.IsArray)))
                .ToList();

            if (orphanParams.Any())
            {
                var orphanCodes = string.Join(", ", orphanParams.Select(p => p.Test.Code));
                throw new Exception($"The following parameters are orphans (not used in any formula): {orphanCodes}. Remove them or use them before validating.");
            }

            form.IsValidated = true;
            form.UserValidatedId = dto.UserId;
            form.DateValidated = DateTime.UtcNow;
            form.CommentsValidated = dto.CommentsValidated;

            var formGroup = await _context.FormGroups.FindAsync(form.FormGroupId);
            if (formGroup != null) formGroup.IsFormValidated = true;

            var testIds = formParams.Select(fp => fp.TestId).ToList();
            if (testIds.Count > 0)
            {
                var tests = await _context.Tests.Where(t => testIds.Contains(t.Id)).ToListAsync();
                foreach (var t in tests)
                {
                    t.IsFormValidated = true;
                    t.DateFormValidated = DateTime.UtcNow;
                }
            }

            await SaveChangesWithDetailedException();
            await transaction.CommitAsync();

            await _signatureService.SignEntityAsync(
                "forms",
                id,
                dto.UserId,
                "Approval",
                "127.0.0.1",
                dto.CommentsValidated);
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    // PUT /forms/{id}/cancel
    public async Task CancelForm(long id, FormActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required for cancellation");

        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (form.IsCancelled) throw new InvalidOperationException("Form already cancelled");

        form.IsCancelled = true;
        form.UserCancelledId = dto.UserId;
        form.DateCancelled = DateTime.UtcNow;
        form.CommentsCancelled = dto.CommentsCancelled;

        await SaveChangesWithDetailedException();
    }

    // PUT /forms/{id}/reactivate
    public async Task ReactivateForm(long id)
    {
        var form = await _context.Forms.FindAsync(id);
        if (form == null) throw new ArgumentException("Form not found");
        if (!form.IsCancelled) throw new InvalidOperationException("Form is not cancelled");

        form.IsCancelled = false;
        form.UserCancelledId = null;
        form.DateCancelled = null;
        form.CommentsCancelled = null;

        await SaveChangesWithDetailedException();
    }

    // POST /forms/{id}/duplicate
    public async Task<IdDto> DuplicateForm(long id, FormActionDto dto)
    {
        if (dto.UserId == 0) throw new ArgumentException("User ID is required for duplication");

        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var originalForm = await _context.Forms.FindAsync(id);
            if (originalForm == null) throw new ArgumentException("Original form not found");

            var newForm = new Form
            {
                FormGroupId = originalForm.FormGroupId,
                Version = $"{originalForm.Version} Copy",
                CustomNav = originalForm.CustomNav,
                IsCustomized = originalForm.IsCustomized,
                IsSubmitted = true, // Start in Submitted state
                UserSubmittedId = dto.UserId,
                DateSubmitted = DateTime.UtcNow,
                IsValidated = false,
                IsCancelled = false
            };

            _context.Forms.Add(newForm);
            await SaveChangesWithDetailedException();

            // Copy Form Parameters
            var originalParams = await _context.FormParams
                .Include(fp => fp.FormConditionEvals)
                .Where(fp => fp.FormId == id)
                .ToListAsync();

            foreach (var p in originalParams)
            {
                var newParam = new FormParam
                {
                    FormId = newForm.Id,
                    TestId = p.TestId,
                    IsCalculated = p.IsCalculated,
                    Formula = p.Formula,
                    CodeRelatedArrays = p.CodeRelatedArrays,
                    HasCondition = p.HasCondition,
                    Condition = p.Condition,
                    ConditionNote = p.ConditionNote,
                    IsRequired = p.IsRequired,
                    DefaultValue = p.DefaultValue,
                    NrOrd = p.NrOrd,
                    NrOrdCalc = p.NrOrdCalc
                };
                _context.FormParams.Add(newParam);

                foreach (var ce in p.FormConditionEvals)
                {
                    _context.FormConditionEvals.Add(new FormConditionEval
                    {
                        FormId = newForm.Id,
                        TestId = ce.TestId,
                        Value = ce.Value,
                        Result = ce.Result,
                        ExpectedResult = ce.ExpectedResult,
                        IsMatch = ce.IsMatch,
                        Note = ce.Note
                    });
                }
            }

            // Copy Evaluation Test Cases (Test Data for Formula Validation)
            var originalEvals = await _context.FormEvals.Include(e => e.FormEvalParams).Where(e => e.FormId == id).ToListAsync();
            foreach (var ev in originalEvals)
            {
                var newEval = new FormEval
                {
                    FormId = newForm.Id,
                    Description = ev.Description
                };
                _context.FormEvals.Add(newEval);
                await SaveChangesWithDetailedException(); // Save to get the newEval.Id

                foreach (var ep in ev.FormEvalParams)
                {
                    _context.FormEvalParams.Add(new FormEvalParam
                    {
                        EvalId = newEval.Id,
                        FormId = newForm.Id,
                        TestId = ep.TestId,
                        Idx = ep.Idx,
                        Value = ep.Value,
                        ExpectedValue = ep.ExpectedValue,
                        IsMatch = ep.IsMatch
                    });
                }
            }

            await SaveChangesWithDetailedException();
            await transaction.CommitAsync();

            return new() { Id = newForm.Id };
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task ValidateFormula(long formId, long testId, bool isCalculated, string? formula)
    {
        await ValidateFormParamFormula(formId, testId, isCalculated, formula);
    }

    public async Task<Dictionary<string, object>> EvaluateFormCalculations(long formId, Dictionary<string, object> measurementData)
    {
        var formParams = await _context.FormParams
            .Include(fp => fp.Test)
            .Where(fp => fp.FormId == formId)
            .OrderBy(fp => fp.NrOrd)
            .ToListAsync();

        // Prepare computationData (Formulas)
        var computationData = new Dictionary<string, FormulaInfo>();
        var calculatedParams = formParams.Where(p => p.IsCalculated).ToList();

        foreach (var p in calculatedParams)
        {
            if (!string.IsNullOrEmpty(p.Formula))
            {
                var deps = !string.IsNullOrEmpty(p.FormulaDependencies)
                    ? p.FormulaDependencies.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(d => d.Trim()).ToList()
                    : new List<string>();

                computationData[p.Test.Code] = new FormulaInfo
                {
                    Formula = p.Formula,
                    Dependencies = deps,
                    ReturnType = QCFormula.Formula.GetFormulaReturnType(p.Formula)
                };
            }
        }

        // Prepare orderedParameters
        var orderedParameters = formParams
            .Where(p => !p.IsCalculated || !string.IsNullOrEmpty(p.Formula))
            .OrderBy(p => p.NrOrdCalc)
            .Select(p => p.Test.Code)
            .ToList();

        // Prepare relatedParameterArrays
        var relatedParameterArrays = formParams
            .Where(p => !p.IsCalculated && p.Test.IsArray && !string.IsNullOrEmpty(p.CodeRelatedArrays))
            .GroupBy(p => p.CodeRelatedArrays!)
            .ToDictionary(g => g.Key, g => g.Select(p => p.Test.Code).ToList());

        try
        {
            return QCFormula.FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, relatedParameterArrays);
        }
        catch (Exception ex)
        {
            throw new Exception($"Evaluation error: {ex.Message}", ex);
        }
    }

    private async Task ValidateFormParamFormula(long formId, long testId, bool isCalculated, string? formula, Form? form = null, Test? test = null)
    {
        form ??= await _context.Forms.FindAsync(formId);
        if (form == null) throw new ArgumentException("Form not found");

        if (isCalculated)
        {
            if (string.IsNullOrWhiteSpace(formula))
            {
                throw new ArgumentException("Formula is required for calculated parameters.");
            }

            test ??= await _context.Tests.FindAsync(testId);
            if (test == null) throw new ArgumentException("Test not found");

            List<string> formulaParams;
            try
            {
                formulaParams = QCFormula.Formula.ExtractParameters(formula);
            }
            catch (Exception ex)
            {
                throw new Exception($"Syntax error: {ex.Message}");
            }

            // Check dependencies
            var formParams = await _context.FormParams
                .Include(fp => fp.Test)
                .Where(fp => fp.FormId == formId)
                .ToListAsync();

            string GetParameterKeyName(string code, bool isArray) => code + (isArray ? "__" : "");
            var availableCodes = formParams.Select(p => GetParameterKeyName(p.Test.Code, p.Test.IsArray)).ToHashSet();
            
            // Also include the current test if it's being added/edited (though circular reference check is handled elsewhere or by the engine)
            // But we don't want a formula to depend on itself.
            
            foreach (var fParam in formulaParams)
            {
                if (!availableCodes.Contains(fParam))
                {
                    var cleanCode = fParam.EndsWith("__") ? fParam.Substring(0, fParam.Length - 2) : fParam;
                    var expectedType = fParam.EndsWith("__") ? "Array [[]]" : "Scalar []";
                    throw new Exception($"Dependency '{cleanCode}' as {expectedType} not found in form.");
                }
            }

            // Cyclic dependency check
            var allDependencies = new Dictionary<string, List<string>>();
            foreach (var fp in formParams)
            {
                if (!fp.IsCalculated) continue;
                
                string currentKey = GetParameterKeyName(fp.Test.Code, fp.Test.IsArray);
                List<string> deps;
                
                if (fp.TestId == testId)
                {
                    deps = formulaParams;
                }
                else
                {
                    if (string.IsNullOrEmpty(fp.Formula))
                    {
                        deps = new List<string>();
                    }
                    else
                    {
                        try {
                            deps = QCFormula.Formula.ExtractParameters(fp.Formula);
                        } catch {
                            deps = new List<string>();
                        }
                    }
                }
                allDependencies[currentKey] = deps;
            }
            
            // If we are adding a new parameter that is not yet in formParams
            string validatingKey = GetParameterKeyName(test.Code, test.IsArray);
            if (!allDependencies.ContainsKey(validatingKey))
            {
                allDependencies[validatingKey] = formulaParams;
            }

            if (QCFormula.DependencyResolver.FindCyclicDependencies(allDependencies))
            {
                throw new Exception("Cyclic dependency detected in formula.");
            }

            try
            {
                var returnType = QCFormula.Formula.GetFormulaReturnType(formula);
                if (!test.IsArray && returnType == FormulaReturnType.Array)
                {
                    throw new Exception($"Expected type is Scalar, but formula returns an Array.");
                }
                if (test.IsArray && returnType == FormulaReturnType.Scalar)
                {
                    throw new Exception($"Expected type is Array, but formula returns a Scalar.");
                }
            }
            catch (Exception ex)
            {
                if (ex.Message.Contains("Expected type is")) throw;
                throw new Exception($"Evaluation error: {ex.Message}");
            }
        }
    }

    private async Task SaveChangesWithDetailedException()
    {
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            var innerMessage = ex.InnerException?.Message ?? ex.Message;
            throw new Exception($"Database update error: {innerMessage}");
        }
        catch (Exception ex)
        {
            throw new Exception($"Error saving changes: {ex.Message}");
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

    private void RecalculateFormConditionEvaluations(string? condition, List<FormConditionEval> evals)
    {
        if (string.IsNullOrWhiteSpace(condition))
        {
            foreach (var eval in evals)
            {
                eval.Result = null;
                eval.IsMatch = false;
            }
            return;
        }

        foreach (var eval in evals)
        {
            var parameters = new Dictionary<string, decimal> { { "value", eval.Value } };
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
}
