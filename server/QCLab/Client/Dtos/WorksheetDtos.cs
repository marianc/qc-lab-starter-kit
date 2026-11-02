using System.Text.Json.Serialization;

namespace QCLab.Client.Dtos;

public class WorksheetTestItemDto
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("measurement_unit")]
    public string MeasurementUnit { get; set; } = string.Empty;

    [JsonPropertyName("value_type")]
    public string ValueType { get; set; } = "real"; // integer, real, boolean, enum

    [JsonPropertyName("enums")]
    public List<string>? Enums { get; set; }

    [JsonPropertyName("is_array")]
    public bool IsArray { get; set; }

    [JsonPropertyName("for_certification")]
    public bool ForCertification { get; set; }

    [JsonPropertyName("formula")]
    public string? Formula { get; set; }

    [JsonPropertyName("formula_dependencies")]
    public string? FormulaDependencies { get; set; }

    [JsonPropertyName("nr_ord_calc")]
    public int NrOrdCalc { get; set; }

    [JsonPropertyName("value")]
    public object? Value { get; set; }

    [JsonPropertyName("code_related_arrays")]
    public string? CodeRelatedArrays { get; set; }

    [JsonPropertyName("condition")]
    public string? Condition { get; set; }

    [JsonPropertyName("condition_note")]
    public string? ConditionNote { get; set; }

    [JsonPropertyName("is_conforming_condition")]
    public bool? IsConformingCondition { get; set; }

    [JsonPropertyName("conforming_results")]
    public List<bool?> ConformingResults { get; set; } = new();
}

public class WorksheetCalculateRequestDto
{
    [JsonPropertyName("items")]
    public List<WorksheetTestItemDto> Items { get; set; } = new();
}

public class WorksheetValidateFormulaRequestDto
{
    [JsonPropertyName("formula")]
    public string? Formula { get; set; }

    [JsonPropertyName("current_code")]
    public string CurrentCode { get; set; } = string.Empty;

    [JsonPropertyName("is_array")]
    public bool IsArray { get; set; }

    [JsonPropertyName("items")]
    public List<WorksheetTestItemDto> Items { get; set; } = new();
}

public class WorksheetItemRequestDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("formula")]
    public string? Formula { get; set; }

    [JsonPropertyName("is_array")]
    public bool IsArray { get; set; }
}

public class CalculateWorksheetRequestDto
{
    [JsonPropertyName("items")]
    public List<WorksheetItemRequestDto> Items { get; set; } = new();
}

public class WorksheetItemResponseDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("formula_dependencies")]
    public string? FormulaDependencies { get; set; }

    [JsonPropertyName("nr_ord_calc")]
    public int NrOrdCalc { get; set; }
}

public class WorksheetValuesItemRequestDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("formula")]
    public string? Formula { get; set; }

    [JsonPropertyName("formula_dependencies")]
    public string? FormulaDependencies { get; set; }

    [JsonPropertyName("nr_ord_calc")]
    public int NrOrdCalc { get; set; }

    [JsonPropertyName("value")]
    public object? Value { get; set; }

    [JsonPropertyName("is_array")]
    public bool IsArray { get; set; }

    [JsonPropertyName("code_related_arrays")]
    public string? CodeRelatedArrays { get; set; }
}

public class WorksheetCalculateValuesRequestDto
{
    [JsonPropertyName("items")]
    public List<WorksheetValuesItemRequestDto> Items { get; set; } = new();
}

public class WorksheetValuesItemResponseDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("value")]
    public object? Value { get; set; }
}

public class WorksheetConformityItemRequestDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("value")]
    public object? Value { get; set; }

    [JsonPropertyName("condition")]
    public string? Condition { get; set; }
}

public class WorksheetCalculateConformityRequestDto
{
    [JsonPropertyName("items")]
    public List<WorksheetConformityItemRequestDto> Items { get; set; } = new();
}

public class WorksheetConformityItemResponseDto
{
    [JsonPropertyName("code")]
    public string Code { get; set; } = string.Empty;

    [JsonPropertyName("is_conforming_condition")]
    public bool? IsConformingCondition { get; set; }

    [JsonPropertyName("conforming_results")]
    public List<bool?> ConformingResults { get; set; } = new();
}
