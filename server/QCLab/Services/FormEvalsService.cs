using Microsoft.EntityFrameworkCore;
using QCFormula;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCLab.Utils;

namespace QCLab.Services;

public class FormEvalsService : IFormEvalsService
{
    private readonly QualityControlContext _context;
    private readonly IServiceProvider _serviceProvider;

    public FormEvalsService(QualityControlContext context, IServiceProvider serviceProvider)
    {
        _context = context;
        _serviceProvider = serviceProvider;
    }

    private IFormsService FormsService => _serviceProvider.GetRequiredService<IFormsService>();

    public async Task<List<FormEvalDto>> GetFormEvals(long formId)
    {
        var evals = await _context.FormEvals
            .Include(e => e.FormEvalParams)
            .Where(e => e.FormId == formId)
            .ToListAsync();

        var formParams = await FormsService.GetFormParams(formId);

        return evals.Select(e => MapToDto(e, formParams)).ToList();
    }

    public async Task<FormEvalDto?> GetFormEval(long id)
    {
        var eval = await _context.FormEvals
            .Include(e => e.FormEvalParams)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (eval == null) return null;

        var formParams = await FormsService.GetFormParams(eval.FormId);

        return MapToDto(eval, formParams);
    }

    public async Task<IdDto> CreateFormEval(CreateFormEvalDto dto)
    {
        var eval = new FormEval
        {
            FormId = dto.FormId,
            Description = dto.Description
        };

        _context.FormEvals.Add(eval);
        await _context.SaveChangesAsync();

        return new IdDto { Id = eval.Id };
    }

    public async Task UpdateFormEval(long id, UpdateFormEvalDto dto)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var eval = await _context.FormEvals
                .Include(e => e.FormEvalParams)
                .FirstOrDefaultAsync(e => e.Id == id);

            if (eval == null) throw new ArgumentException("Form eval not found");

            eval.Description = dto.Description;

            // Remove existing params
            _context.FormEvalParams.RemoveRange(eval.FormEvalParams);
            await _context.SaveChangesAsync();

            var formParams = await FormsService.GetFormParams(eval.FormId);

            // 1. Process Measurement Data (Inputs)
            if (dto.MeasurementData != null)
            {
                var flatInputs = FormEvalMapper.MapDictToFlat(dto.MeasurementData, formParams.Where(p => !p.IsCalculated).ToList());
                foreach (var item in flatInputs)
                {
                    _context.FormEvalParams.Add(new FormEvalParam
                    {
                        EvalId = id,
                        FormId = eval.FormId,
                        TestId = item.TestId,
                        Idx = item.Idx,
                        Value = item.Value,
                        ExpectedValue = null, 
                        IsMatch = false
                    });
                }
            }

            // 2. Process Expected Results
            if (dto.ExpectedResults != null)
            {
                var flatExpected = FormEvalMapper.MapDictToFlat(dto.ExpectedResults, formParams.Where(p => p.IsCalculated).ToList());
                foreach (var item in flatExpected)
                {
                    _context.FormEvalParams.Add(new FormEvalParam
                    {
                        EvalId = id,
                        FormId = eval.FormId,
                        TestId = item.TestId,
                        Idx = item.Idx,
                        Value = null, // Actual value will be calculated later
                        ExpectedValue = item.Value,
                        IsMatch = false
                    });
                }
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }

        await CalculateFormEval(id);
    }

    public async Task DeleteFormEval(long id)
    {
        using var transaction = await _context.Database.BeginTransactionAsync();
        try
        {
            var params_ = await _context.FormEvalParams.Where(p => p.EvalId == id).ToListAsync();
            _context.FormEvalParams.RemoveRange(params_);

            var eval = await _context.FormEvals.FindAsync(id);
            if (eval != null)
            {
                _context.FormEvals.Remove(eval);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    public async Task<FormEvalDto> CalculateFormEval(long id)
    {
        var eval = await _context.FormEvals
            .Include(e => e.FormEvalParams)
            .Include(e => e.Form)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (eval == null) throw new ArgumentException("Form eval not found");

        var formId = eval.FormId;
        var formParams = await FormsService.GetFormParams(formId);

        // 1. Prepare measurementData (Inputs) using FormEvalMapper.MapFlatToDict
        var inputParamIds = formParams.Where(fp => !fp.IsCalculated).Select(fp => fp.TestId).ToHashSet();
        var flatInputs = eval.FormEvalParams
            .Where(p => inputParamIds.Contains(p.TestId) && p.Value.HasValue)
            .Select(p => new MeasurementFlatData { TestId = p.TestId, Idx = p.Idx, Value = p.Value!.Value })
            .ToList();

        var measurementData = FormEvalMapper.MapFlatToDict(flatInputs, formParams.Where(p => !p.IsCalculated).ToList());

        // Call EvaluateFormCalculations from FormsService
        Dictionary<string, object> results;
        try
        {
            results = await FormsService.EvaluateFormCalculations(formId, measurementData!);
        }
        catch (Exception ex)
        {
            throw new Exception($"Evaluation error: {ex.Message}", ex);
        }

        // 5. Update database with results
        var calcParams = formParams.Where(p => p.IsCalculated).ToList();
        var calcParamIds = calcParams.Select(p => p.TestId).ToHashSet();

        // 5a. Capture existing ExpectedValues before clearing
        var existingExpected = eval.FormEvalParams
            .Where(p => calcParamIds.Contains(p.TestId) && p.ExpectedValue.HasValue)
            .ToDictionary(p => (p.TestId, p.Idx), p => p.ExpectedValue!.Value);

        // 5b. Get calculated results in flat format (non-nulls)
        var flatResults = FormEvalMapper.MapDictToFlat(results!, calcParams)
            .ToDictionary(p => (p.TestId, p.Idx), p => p.Value);

        // 5c. Identify all keys that should have a row
        var keysToCreate = new HashSet<(long testId, int idx)>();
        foreach (var k in existingExpected.Keys) keysToCreate.Add(k);
        foreach (var k in flatResults.Keys) keysToCreate.Add(k);
        // Ensure at least index 0 for any calculated param that is in results dictionary (even if null)
        foreach (var p in calcParams) if (results.ContainsKey(p.Code)) keysToCreate.Add((p.TestId, 0));

        // 5d. Remove existing calculated rows
        var existingCalcRows = eval.FormEvalParams.Where(p => calcParamIds.Contains(p.TestId)).ToList();
        _context.FormEvalParams.RemoveRange(existingCalcRows);

        foreach (var key in keysToCreate)
        {
            decimal? calculatedVal = flatResults.TryGetValue(key, out decimal cv) ? cv : (decimal?)null;
            decimal? expectedVal = existingExpected.TryGetValue(key, out decimal ev) ? ev : (decimal?)null;

            if (!calculatedVal.HasValue && !expectedVal.HasValue) continue;
            
            var newParam = new FormEvalParam
            {
                EvalId = id,
                FormId = formId,
                TestId = key.testId,
                Idx = key.idx,
                Value = calculatedVal,
                ExpectedValue = expectedVal,
                IsMatch = false
            };
            UpdateIsMatch(newParam, formParams);
            _context.FormEvalParams.Add(newParam);
        }

        await _context.SaveChangesAsync();
        // Refresh local collection to get updated state for MapToDto
        eval.FormEvalParams = await _context.FormEvalParams.Where(p => p.EvalId == id).ToListAsync();
        return MapToDto(eval, formParams);
    }

    private void UpdateIsMatch(FormEvalParam p, List<FormParamDto> formParams)
    {
        if (p.ExpectedValue.HasValue && p.Value.HasValue)
        {
            p.IsMatch = p.Value.Value == p.ExpectedValue.Value;
        }
        else
        {
            p.IsMatch = false;
        }
    }

    private FormEvalDto MapToDto(FormEval e, List<FormParamDto> formParams)
    {
        var dto = new FormEvalDto
        {
            Id = e.Id,
            FormId = e.FormId,
            Description = e.Description,
            MeasurementData = new Dictionary<string, object?>(),
            CalculatedResults = new Dictionary<string, object?>(),
            ExpectedResults = new Dictionary<string, EvalResultDto>()
        };

        var groupedEvalParams = e.FormEvalParams.GroupBy(p => p.TestId).ToDictionary(g => g.Key, g => g.ToList());

        // Use FormEvalMapper.MapFlatToDict to reconstruct MeasurementData and CalculatedResults
        var flatAll = e.FormEvalParams
            .Where(p => p.Value.HasValue)
            .Select(p => new MeasurementFlatData { TestId = p.TestId, Idx = p.Idx, Value = p.Value!.Value })
            .ToList();
        var allData = FormEvalMapper.MapFlatToDict(flatAll, formParams);

        // For expected results of calculated fields
        var inputParamIds = formParams.Where(fp => !fp.IsCalculated).Select(fp => fp.TestId).ToHashSet();
        var flatCalculatedExpected = e.FormEvalParams
            .Where(p => !inputParamIds.Contains(p.TestId) && p.ExpectedValue.HasValue)
            .Select(p => new MeasurementFlatData { TestId = p.TestId, Idx = p.Idx, Value = p.ExpectedValue!.Value })
            .ToList();
        var reconstructedExpected = FormEvalMapper.MapFlatToDict(flatCalculatedExpected, formParams.Where(p => p.IsCalculated).ToList());
        foreach (var paramInfo in formParams)
        {
            string code = paramInfo.Code;
            
            if (!paramInfo.IsCalculated)
            {
                dto.MeasurementData[code] = allData.TryGetValue(code, out var v) ? v : null;
            }
            else
            {
                dto.CalculatedResults[code] = allData.TryGetValue(code, out var v) ? v : null;
                object? expected = reconstructedExpected.TryGetValue(code, out var ex) ? ex : null;
                
                // Construct isMatchObj
                object isMatchObj;
                if (paramInfo.IsArray)
                {
                    var valList = dto.CalculatedResults[code] as List<decimal?>;
                    var expList = expected as List<decimal?>;
                    
                    long maxCount = 0;
                    if (valList != null) maxCount = Math.Max(maxCount, valList.Count);
                    if (expList != null) maxCount = Math.Max(maxCount, expList.Count);

                    if (maxCount > 0)
                    {
                        var matchList = new List<bool>(new bool[maxCount]);
                        if (groupedEvalParams.TryGetValue(paramInfo.TestId, out var group))
                        {
                            foreach (var item in group) if (item.Idx < matchList.Count) matchList[item.Idx] = item.IsMatch;
                        }
                        isMatchObj = matchList;
                    }
                    else
                    {
                        isMatchObj = false;
                    }
                }
                else
                {
                    isMatchObj = groupedEvalParams.TryGetValue(paramInfo.TestId, out var group) ? group.First().IsMatch : false;
                }

                dto.ExpectedResults[code] = new EvalResultDto { Value = expected, IsMatch = isMatchObj };
            }
        }

        return dto;
    }
}
