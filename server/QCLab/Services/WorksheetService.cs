using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCFormula;
using System.Text.Json;

namespace QCLab.Services;

public class WorksheetService : IWorksheetService
{
    private readonly QualityControlContext _context;

    public WorksheetService(QualityControlContext context)
    {
        _context = context;
    }

    public async Task<List<WorksheetItemResponseDto>> CalculateWorksheet(List<WorksheetItemRequestDto> requestItems)
    {
        if (requestItems == null || requestItems.Count == 0)
            return new List<WorksheetItemResponseDto>();

        var testItems = requestItems.Select(r => new WorksheetTestItemDto
        {
            Code = r.Code,
            Formula = r.Formula,
            IsArray = r.IsArray
        }).ToList();

        var calculatedItems = await CalculateWorksheetInternal(testItems);

        return calculatedItems.Select(i => new WorksheetItemResponseDto
        {
            Code = i.Code,
            FormulaDependencies = i.FormulaDependencies,
            NrOrdCalc = i.NrOrdCalc
        }).ToList();
    }

    public async Task<List<WorksheetTestItemDto>> CalculateWorksheetInternal(List<WorksheetTestItemDto> items)
    {
        if (items == null || items.Count == 0)
            return new List<WorksheetTestItemDto>();

        foreach (var item in items)
        {
            if (string.IsNullOrEmpty(item.Id))
            {
                item.Id = $"test_{Guid.NewGuid():N}";
            }
        }

        // 0. Ensure all dependencies exist in items as input parameters if missing
        var existingCodes = items.Select(i => i.Code).ToHashSet(StringComparer.OrdinalIgnoreCase);
        var missingCodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var item in items)
        {
            if (!string.IsNullOrWhiteSpace(item.Formula))
            {
                try
                {
                    var deps = QCFormula.Formula.ExtractParameters(item.Formula);
                    foreach (var dep in deps)
                    {
                        var cleanDep = dep.EndsWith("__") ? dep.Substring(0, dep.Length - 2) : dep;
                        if (!existingCodes.Contains(cleanDep) && !existingCodes.Contains(dep))
                        {
                            missingCodes.Add(cleanDep);
                        }
                    }
                }
                catch { }
            }
        }

        foreach (var missingCode in missingCodes)
        {
            items.Add(new WorksheetTestItemDto
            {
                Id = $"dep_{Guid.NewGuid():N}",
                Name = missingCode,
                Code = missingCode,
                ValueType = "real",
                IsArray = false,
                Value = 1.0m,
                ConditionNote = "Pass",
                IsConformingCondition = true
            });
            existingCodes.Add(missingCode);
        }

        // 1. Extract formula dependencies
        foreach (var item in items)
        {
            if (!string.IsNullOrWhiteSpace(item.Formula))
            {
                try
                {
                    var deps = QCFormula.Formula.ExtractParameters(item.Formula);
                    var cleanDeps = deps.Select(d => d.EndsWith("__") ? d.Substring(0, d.Length - 2) : d).ToList();
                    item.FormulaDependencies = cleanDeps.Count > 0 ? string.Join(", ", cleanDeps) : null;
                }
                catch
                {
                    item.FormulaDependencies = null;
                }
            }
            else
            {
                item.FormulaDependencies = null;
            }
        }

        // 2. Determine ordered parameters & assign NrOrdCalc
        var nonCalculatedCodes = items.Where(i => string.IsNullOrWhiteSpace(i.Formula)).Select(i => i.Code).ToList();
        var calculatedCodes = items.Where(i => !string.IsNullOrWhiteSpace(i.Formula)).Select(i => i.Code).ToList();

        var orderedCodes = new List<string>();
        orderedCodes.AddRange(nonCalculatedCodes);
        orderedCodes.AddRange(calculatedCodes);

        var computationData = new Dictionary<string, FormulaInfo>();
        foreach (var item in items)
        {
            if (!string.IsNullOrWhiteSpace(item.Formula))
            {
                var deps = !string.IsNullOrEmpty(item.FormulaDependencies)
                    ? item.FormulaDependencies.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(d => d.Trim()).ToList()
                    : new List<string>();
                var cleanDeps = deps.Select(d => d.EndsWith("__") ? d.Substring(0, d.Length - 2) : d).ToList();
                computationData[item.Code] = new FormulaInfo
                {
                    Formula = item.Formula!,
                    Dependencies = cleanDeps
                };
            }
        }

        var allDependencies = computationData.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.Dependencies);
        var reorderedCalculated = QCFormula.Formula.ReorderParametersByDependencies(orderedCodes, allDependencies);

        var finalOrderedParameters = new List<string>();
        finalOrderedParameters.AddRange(nonCalculatedCodes);
        finalOrderedParameters.AddRange(reorderedCalculated);

        for (int i = 0; i < finalOrderedParameters.Count; i++)
        {
            var code = finalOrderedParameters[i];
            var item = items.FirstOrDefault(it => it.Code == code);
            if (item != null)
            {
                item.NrOrdCalc = i + 1;
            }
        }

        return await Task.FromResult(items);
    }

    public async Task<List<WorksheetValuesItemResponseDto>> CalculateValues(List<WorksheetValuesItemRequestDto> requestItems)
    {
        if (requestItems == null || requestItems.Count == 0)
            return new List<WorksheetValuesItemResponseDto>();

        var testItems = requestItems.Select(r => new WorksheetTestItemDto
        {
            Code = r.Code,
            Formula = r.Formula,
            FormulaDependencies = r.FormulaDependencies,
            NrOrdCalc = r.NrOrdCalc,
            Value = r.Value,
            IsArray = r.IsArray,
            CodeRelatedArrays = r.CodeRelatedArrays
        }).ToList();

        var calculatedItems = await CalculateValuesInternal(testItems);

        return calculatedItems.Select(i => new WorksheetValuesItemResponseDto
        {
            Code = i.Code,
            Value = i.Value
        }).ToList();
    }

    public async Task<List<WorksheetTestItemDto>> CalculateValuesInternal(List<WorksheetTestItemDto> items)
    {
        if (items == null || items.Count == 0)
            return new List<WorksheetTestItemDto>();

        var measurementData = new Dictionary<string, object>();
        var computationData = new Dictionary<string, FormulaInfo>();

        foreach (var item in items)
        {
            if (string.IsNullOrEmpty(item.Id))
            {
                item.Id = $"test_{Guid.NewGuid():N}";
            }

            bool isCalculated = !string.IsNullOrWhiteSpace(item.Formula);
            if (isCalculated)
            {
                var deps = !string.IsNullOrEmpty(item.FormulaDependencies)
                    ? item.FormulaDependencies.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(d => d.Trim()).ToList()
                    : new List<string>();
                var cleanDeps = deps.Select(d => d.EndsWith("__") ? d.Substring(0, d.Length - 2) : d).ToList();

                FormulaReturnType returnType;
                try
                {
                    returnType = QCFormula.Formula.GetFormulaReturnType(item.Formula!);
                }
                catch
                {
                    returnType = item.IsArray ? FormulaReturnType.Array : FormulaReturnType.Scalar;
                }

                computationData[item.Code] = new FormulaInfo
                {
                    Formula = item.Formula!,
                    Dependencies = cleanDeps,
                    ReturnType = returnType
                };
            }
            else
            {
                measurementData[item.Code] = ConvertToEvaluationValue(item.Value, item.IsArray, item.ValueType);
            }
        }

        var nonCalculatedCodes = items.Where(i => string.IsNullOrWhiteSpace(i.Formula)).Select(i => i.Code).ToList();
        var calculatedCodes = items.Where(i => !string.IsNullOrWhiteSpace(i.Formula)).Select(i => i.Code).ToList();

        var orderedCodes = new List<string>();
        orderedCodes.AddRange(nonCalculatedCodes);
        orderedCodes.AddRange(calculatedCodes);

        var allDependencies = computationData.ToDictionary(kvp => kvp.Key, kvp => kvp.Value.Dependencies);
        var reorderedCalculated = QCFormula.Formula.ReorderParametersByDependencies(orderedCodes, allDependencies);

        var finalOrderedParameters = new List<string>();
        finalOrderedParameters.AddRange(nonCalculatedCodes);
        finalOrderedParameters.AddRange(reorderedCalculated);

        var relatedParameterArrays = items
            .Where(i => string.IsNullOrWhiteSpace(i.Formula) && i.IsArray && !string.IsNullOrWhiteSpace(i.CodeRelatedArrays))
            .GroupBy(i => i.CodeRelatedArrays!)
            .ToDictionary(g => g.Key, g => g.Select(i => i.Code).ToList());

        Dictionary<string, object> evalResults = new();
        try
        {
            evalResults = QCFormula.FormEvaluator.EvaluateForm(measurementData, computationData, finalOrderedParameters, relatedParameterArrays);
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Worksheet values evaluation warning: {ex.Message}");
        }

        foreach (var item in items)
        {
            bool isCalculated = !string.IsNullOrWhiteSpace(item.Formula);
            if (isCalculated)
            {
                if (evalResults.TryGetValue(item.Code, out var res))
                {
                    item.Value = ConvertResultToDtoValue(res);
                }
            }
            else
            {
                if (measurementData.TryGetValue(item.Code, out var mVal))
                {
                    item.Value = ConvertResultToDtoValue(mVal);
                }
            }
        }

        return await Task.FromResult(items);
    }

    public async Task<List<WorksheetConformityItemResponseDto>> CalculateConformity(List<WorksheetConformityItemRequestDto> requestItems)
    {
        if (requestItems == null || requestItems.Count == 0)
            return new List<WorksheetConformityItemResponseDto>();

        var testItems = requestItems.Select(r => new WorksheetTestItemDto
        {
            Code = r.Code,
            Value = r.Value,
            Condition = r.Condition
        }).ToList();

        var calculatedItems = await CalculateConformityInternal(testItems);

        return calculatedItems.Select(i => new WorksheetConformityItemResponseDto
        {
            Code = i.Code,
            IsConformingCondition = i.IsConformingCondition,
            ConformingResults = i.ConformingResults
        }).ToList();
    }

    public async Task<List<WorksheetTestItemDto>> CalculateConformityInternal(List<WorksheetTestItemDto> items)
    {
        if (items == null || items.Count == 0)
            return new List<WorksheetTestItemDto>();

        foreach (var item in items)
        {
            if (string.IsNullOrEmpty(item.Id))
            {
                item.Id = $"test_{Guid.NewGuid():N}";
            }

            if (!string.IsNullOrWhiteSpace(item.Condition))
            {
                if (item.Value == null || (item.Value is string s && string.IsNullOrWhiteSpace(s)) || (item.Value is System.Collections.IEnumerable list && !list.Cast<object>().Any()))
                {
                    item.IsConformingCondition = false;
                    item.ConformingResults = new List<bool?> { false };
                }
                else
                {
                    var results = GetConformingResults(item.Condition, item.Value);
                    item.ConformingResults = results;
                    item.IsConformingCondition = results.Count > 0 ? results.All(r => r == true) : (bool?)null;
                }
            }
            else
            {
                item.IsConformingCondition = null;
                item.ConformingResults = new List<bool?>();
            }
        }

        return await Task.FromResult(items);
    }

    public async Task<List<WorksheetTestItemDto>> CalculateWorksheet(List<WorksheetTestItemDto> items)
    {
        var step1 = await CalculateWorksheetInternal(items);
        var step2 = await CalculateValuesInternal(step1);
        return await CalculateConformityInternal(step2);
    }

    public async Task<List<WorksheetTestItemDto>> ImportFormEval(long formEvalId)
    {
        var formEval = await _context.FormEvals
            .Include(e => e.Form)
                .ThenInclude(f => f.FormParams)
                    .ThenInclude(fp => fp.Test)
                        .ThenInclude(t => t.Type)
            .Include(e => e.Form)
                .ThenInclude(f => f.FormParams)
                    .ThenInclude(fp => fp.Test)
                        .ThenInclude(t => t.Unit)
            .Include(e => e.Form)
                .ThenInclude(f => f.FormParams)
                    .ThenInclude(fp => fp.Test)
                        .ThenInclude(t => t.TestEnums)
            .Include(e => e.FormEvalParams)
            .FirstOrDefaultAsync(e => e.Id == formEvalId);

        if (formEval == null || formEval.Form == null || formEval.Form.FormParams == null)
            return new List<WorksheetTestItemDto>();

        var formParams = formEval.Form.FormParams.OrderBy(fp => fp.NrOrd).ToList();
        var evalParams = formEval.FormEvalParams.ToList();

        var items = new List<WorksheetTestItemDto>();

        foreach (var fp in formParams)
        {
            var test = fp.Test;
            if (test == null) continue;

            var paramRows = evalParams.Where(ep => ep.TestId == test.Id).OrderBy(ep => ep.Idx).ToList();

            object? val = null;

            if (paramRows.Any())
            {
                if (test.IsArray)
                {
                    val = paramRows.Select(ep => (object?)ep.Value).ToList();
                }
                else
                {
                    val = paramRows.First().Value;
                }
            }

            List<string>? enums = null;
            if (test.Type?.Name?.ToLower() == "enum" && test.TestEnums != null && test.TestEnums.Any())
            {
                enums = test.TestEnums.OrderBy(e => e.NrOrd).Select(e => e.Name).ToList();
            }

            items.Add(new WorksheetTestItemDto
            {
                Name = test.Name,
                Code = test.Code,
                Description = test.Description,
                MeasurementUnit = test.Unit?.Name ?? string.Empty,
                ValueType = test.Type?.Name?.ToLower() ?? "real",
                Enums = enums,
                IsArray = test.IsArray,
                ForCertification = test.ForCertification,
                Formula = fp.Formula,
                FormulaDependencies = fp.FormulaDependencies,
                NrOrdCalc = (int)fp.NrOrdCalc,
                Value = val,
                CodeRelatedArrays = fp.CodeRelatedArrays,
                Condition = fp.Condition,
                ConditionNote = fp.ConditionNote ?? string.Empty
            });
        }

        return await Task.FromResult(items);
    }

    public async Task<List<FormEvalImportOptionDto>> GetImportableFormEvals()
    {
        var evals = await _context.FormEvals
            .Include(e => e.Form)
                .ThenInclude(f => f.FormGroup)
            .Where(e => e.Form != null && e.Form.IsValidated && !e.Form.IsCancelled)
            .OrderBy(e => e.Form.FormGroup.NrOrd)
            .ThenBy(e => e.FormId)
            .ToListAsync();

        return evals.Select(e => new FormEvalImportOptionDto
        {
            Id = e.Id,
            Label = $"{e.Form.FormGroup.Name} ({e.Form.Version}) - [{e.Id}] {e.Description ?? string.Empty}"
        }).ToList();
    }

    private object? ConvertToEvaluationValue(object? val, bool isArray, string valueType)
    {
        if (val == null || (val is string s && string.IsNullOrWhiteSpace(s)))
        {
            return null;
        }

        if (isArray)
        {
            var list = new List<decimal?>();
            if (val is JsonElement je && je.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in je.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Null)
                    {
                        list.Add(null);
                    }
                    else if (item.ValueKind == JsonValueKind.Number && item.TryGetDecimal(out decimal d))
                    {
                        list.Add(d);
                    }
                    else if (item.ValueKind == JsonValueKind.String)
                    {
                        var str = item.GetString();
                        if (string.IsNullOrWhiteSpace(str)) list.Add(null);
                        else if (decimal.TryParse(str, out decimal ds)) list.Add(ds);
                        else list.Add(null);
                    }
                    else if (item.ValueKind == JsonValueKind.True)
                    {
                        list.Add(1m);
                    }
                    else if (item.ValueKind == JsonValueKind.False)
                    {
                        list.Add(0m);
                    }
                    else
                    {
                        list.Add(null);
                    }
                }
            }
            else if (val is IEnumerable<object?> enumerable)
            {
                foreach (var obj in enumerable)
                {
                    if (obj == null)
                    {
                        list.Add(null);
                    }
                    else if (obj is decimal dec)
                    {
                        list.Add(dec);
                    }
                    else if (obj is JsonElement objJe)
                    {
                        if (objJe.ValueKind == JsonValueKind.Null) list.Add(null);
                        else if (objJe.ValueKind == JsonValueKind.Number && objJe.TryGetDecimal(out decimal dd)) list.Add(dd);
                        else if (decimal.TryParse(objJe.ToString(), out decimal dds)) list.Add(dds);
                        else list.Add(null);
                    }
                    else if (decimal.TryParse(obj.ToString(), out var d))
                    {
                        list.Add(d);
                    }
                    else
                    {
                        list.Add(null);
                    }
                }
            }
            else if (val is IEnumerable<decimal?> decs)
            {
                list.AddRange(decs);
            }
            else if (val is IEnumerable<decimal> decsPrimitive)
            {
                foreach (var dec in decsPrimitive) list.Add(dec);
            }
            return list.Count > 0 ? list : null;
        }
        else
        {
            if (val is JsonElement je)
            {
                if (je.ValueKind == JsonValueKind.Null) return null;
                if (je.ValueKind == JsonValueKind.Number) return je.GetDecimal();
                if (je.ValueKind == JsonValueKind.String)
                {
                    var str = je.GetString();
                    if (string.IsNullOrWhiteSpace(str)) return null;
                    if (decimal.TryParse(str, out var d)) return d;
                }
                if (je.ValueKind == JsonValueKind.True) return 1m;
                if (je.ValueKind == JsonValueKind.False) return 0m;
            }
            if (val != null && decimal.TryParse(val.ToString(), out var dVal))
            {
                return dVal;
            }
            return null;
        }
    }

    private decimal GetDefaultScalarValue(string valueType)
    {
        return valueType switch
        {
            "integer" => 1m,
            "real" => 1.0m,
            "boolean" => 1m,
            "enum" => 1m,
            _ => 1.0m
        };
    }

    private object? ConvertResultToDtoValue(object? res)
    {
        if (res is List<decimal> decList)
        {
            return decList.Cast<object?>().ToList();
        }
        if (res is List<decimal?> decNullableList)
        {
            return decNullableList.Cast<object?>().ToList();
        }
        return res;
    }

    private bool EvaluateCondition(string condition, object? value)
    {
        if (value == null) return true;

        if (value is IEnumerable<object> enumObjList)
        {
            foreach (var obj in enumObjList)
            {
                if (decimal.TryParse(obj?.ToString(), out var d))
                {
                    if (!EvaluateSingleCondition(condition, d)) return false;
                }
            }
            return true;
        }
        else if (value is IEnumerable<decimal> decList)
        {
            foreach (var d in decList)
            {
                if (!EvaluateSingleCondition(condition, d)) return false;
            }
            return true;
        }
        else if (decimal.TryParse(value.ToString(), out var d))
        {
            return EvaluateSingleCondition(condition, d);
        }

        return true;
    }

    private bool EvaluateSingleCondition(string condition, decimal value)
    {
        try
        {
            var parameters = new Dictionary<string, decimal> { { "value", value } };
            var result = QCFormula.Formula.EvaluateFormula(condition, parameters);
            if (result is bool b) return b;
            if (result is decimal d) return d != 0.0m;
            if (result is long l) return l != 0;
            return true;
        }
        catch
        {
            return true;
        }
    }

    private List<bool?> GetConformingResults(string condition, object? value)
    {
        var results = new List<bool?>();
        if (value == null) return results;

        IEnumerable<object?> itemsToEvaluate;
        if (value is JsonElement je && je.ValueKind == JsonValueKind.Array)
        {
            itemsToEvaluate = je.EnumerateArray().Select(x => (object?)(x.ValueKind == JsonValueKind.Null ? null : x.ToString()));
        }
        else if (value is System.Collections.IEnumerable enumerable && !(value is string))
        {
            itemsToEvaluate = enumerable.Cast<object?>();
        }
        else
        {
            itemsToEvaluate = new List<object?> { value };
        }

        foreach (var obj in itemsToEvaluate)
        {
            if (obj == null || (obj is string str && string.IsNullOrWhiteSpace(str)) || (obj is JsonElement jeElem && jeElem.ValueKind == JsonValueKind.Null))
            {
                results.Add(false);
            }
            else if (decimal.TryParse(obj.ToString(), out var d))
            {
                results.Add(EvaluateSingleCondition(condition, d));
            }
            else
            {
                results.Add(false);
            }
        }
        return results;
    }

    public void ValidateWorksheetFormula(string? formula, string currentCode, bool isArray, List<WorksheetTestItemDto> items)
    {
        if (string.IsNullOrWhiteSpace(formula)) return;

        List<string> formulaParams;
        try
        {
            formulaParams = QCFormula.Formula.ExtractParameters(formula);
        }
        catch (Exception ex)
        {
            throw new Exception($"Syntax error: {ex.Message}");
        }

        string GetParameterKeyName(string code, bool isArrayProp) => code + (isArrayProp ? "__" : "");
        var availableCodes = items != null 
            ? items.Select(i => GetParameterKeyName(i.Code.Trim(), i.IsArray)).ToHashSet(StringComparer.OrdinalIgnoreCase)
            : new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        if (!string.IsNullOrWhiteSpace(currentCode))
        {
            availableCodes.Add(GetParameterKeyName(currentCode.Trim(), isArray));
        }

        foreach (var fParam in formulaParams)
        {
            if (!availableCodes.Contains(fParam))
            {
                var cleanCode = fParam.EndsWith("__") ? fParam.Substring(0, fParam.Length - 2) : fParam;
                var expectedType = fParam.EndsWith("__" ) ? "Array [[]]" : "Scalar []";
                throw new Exception($"Dependency '{cleanCode}' as {expectedType} not found in test items.");
            }
        }

        // Cyclic dependency check
        var allDependencies = new Dictionary<string, List<string>>();
        string validatingKey = GetParameterKeyName(currentCode?.Trim() ?? "current", isArray);
        allDependencies[validatingKey] = formulaParams;

        if (QCFormula.DependencyResolver.FindCyclicDependencies(allDependencies))
        {
            throw new Exception("Cyclic dependency detected in formula.");
        }

        try
        {
            var returnType = QCFormula.Formula.GetFormulaReturnType(formula);
            if (!isArray && returnType == FormulaReturnType.Array)
            {
                throw new Exception($"Expected type is Scalar, but formula returns an Array.");
            }
            if (isArray && returnType == FormulaReturnType.Scalar)
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
