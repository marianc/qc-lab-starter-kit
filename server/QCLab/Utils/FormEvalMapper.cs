using QCFormula;
using QCLab.Client.Dtos;

namespace QCLab.Utils;

public static class FormEvalMapper
{
    public static List<MeasurementFlatData> MapDictToFlat(Dictionary<string, object?> data, List<FormParamDto> formParams)
    {
        var parameters = formParams.ToDictionary(p => p.Code, p => new ParameterDefinition { TestId = p.TestId, IsArray = p.IsArray });
        var measurementData = data.Where(kvp => kvp.Value != null).ToDictionary(kvp => kvp.Key, kvp => kvp.Value!);
        return DataMapper.MapDictToFlat(measurementData, parameters);
    }

    public static Dictionary<string, object?> MapFlatToDict(List<MeasurementFlatData> flatParams, List<FormParamDto> formParamsSchema)
    {
        var parameters = formParamsSchema.ToDictionary(p => p.Code, p => new ParameterDefinition { TestId = p.TestId, IsArray = p.IsArray });
        var relatedParameterArrays = formParamsSchema
            .Where(p => !string.IsNullOrEmpty(p.CodeRelatedArrays))
            .GroupBy(p => p.CodeRelatedArrays!)
            .ToDictionary(g => g.Key, g => g.Select(p => p.Code).ToList());

        var dict = DataMapper.MapFlatToDict(flatParams, parameters, relatedParameterArrays);
        return dict.ToDictionary(kvp => kvp.Key, kvp => (object?)kvp.Value);
    }

    public static Dictionary<string, object?> MapConditionToDict(List<MeasurementFlatData> flatParams, List<FormParamDto> formParamsSchema)
    {
        var parameters = formParamsSchema.ToDictionary(p => p.Code, p => new ParameterDefinition { TestId = p.TestId, IsArray = p.IsArray });
        var relatedParameterArrays = formParamsSchema
            .Where(p => !string.IsNullOrEmpty(p.CodeRelatedArrays))
            .GroupBy(p => p.CodeRelatedArrays!)
            .ToDictionary(g => g.Key, g => g.Select(p => p.Code).ToList());

        var flatConditions = flatParams.Where(p => p.ConditionValue.HasValue)
            .Select(p => new MeasurementFlatData { TestId = p.TestId, Idx = p.Idx, Value = p.ConditionValue!.Value })
            .ToList();

        var dict = DataMapper.MapFlatToDict(flatConditions, parameters, relatedParameterArrays);
        return dict.ToDictionary(kvp => kvp.Key, kvp => (object?)kvp.Value);
    }
}
