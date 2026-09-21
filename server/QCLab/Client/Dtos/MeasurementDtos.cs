using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace QCLab.Client.Dtos;

public class MeasurementDto
{
    public long Id { get; set; }
    public long ReceptionId { get; set; }
    public long? FormId { get; set; }
    public string? Comments { get; set; }
    public bool IsReported { get; set; }
    public bool IsReadonly { get; set; }
    public long UserUpdateId { get; set; }
    public string? UserUpdateTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime DateUpdate { get; set; }
    public List<MeasurementTestDto>? Tests { get; set; }
    
    [JsonIgnore]
    public List<MeasurementFormParamSchemaDto>? FormParamsSchema { get; set; }
    public Dictionary<string, object?>? FormDataValues { get; set; }
}

public class MeasurementTestDetailDto
{
    public long Id { get; set; }
    public long ReceptionId { get; set; }
    public string? Comments { get; set; }
    public bool UseDefaultEquipment { get; set; }
    public bool IsReported { get; set; }
    public bool IsReadonly { get; set; }
    public long UserUpdateId { get; set; }
    public string? UserUpdateTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime DateUpdate { get; set; }
    public List<MeasurementTestDto> Tests { get; set; } = new();
}

public class MeasurementParamDetailDto
{
    public long Id { get; set; }
    public long ReceptionId { get; set; }
    public long FormId { get; set; }
    public string? Comments { get; set; }
    public bool UseDefaultEquipment { get; set; }
    public bool IsReported { get; set; }
    public bool IsReadonly { get; set; }
    public long UserUpdateId { get; set; }
    public string? UserUpdateTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime DateUpdate { get; set; }

    [JsonIgnore]
    public List<MeasurementFormParamSchemaDto>? FormParamsSchema { get; set; }
    public Dictionary<string, object?> MeasurementData { get; set; } = new();
    public Dictionary<string, object?> CalculatedResults { get; set; } = new();
    public Dictionary<string, object?> ConditionPass { get; set; } = new();
}

public class MeasurementTestDto
{
    [Required(ErrorMessage = "Test is required.")]
    [Range(1, long.MaxValue, ErrorMessage = "Test is required.")]
    public long TestId { get; set; }

    [Required(ErrorMessage = "Value is required.")]
    public object Value { get; set; } = 0;
    public string? Note { get; set; }
}

public class CreateMeasurementDto
{
    public long ReceptionId { get; set; }
    public string? Comments { get; set; }
    public bool IsReported { get; set; }
    public long? FormId { get; set; }
}

public class UpdateMeasurementTestBulkDto
{
    public string? Comments { get; set; }
    public bool UseDefaultEquipment { get; set; }
    public bool IsReported { get; set; }
    public List<MeasurementTestDto>? Tests { get; set; }
}

public class UpdateMeasurementParamDto
{
    public string? Comments { get; set; }
    public bool UseDefaultEquipment { get; set; }
    public bool IsReported { get; set; }
    public Dictionary<string, object?> MeasurementData { get; set; } = new();
}

public class MeasurementFormParamSchemaDto
{
    public long TestId { get; set; }
    public required string Code { get; set; }
    public required string Name { get; set; }
    public long TypeId { get; set; }
    public bool IsParam { get; set; }
    public bool IsArray { get; set; }
    public bool IsCalculated { get; set; }
    public string? Formula { get; set; }
    public decimal? DefaultValue { get; set; }
    public long NrOrd { get; set; }
    public string? CodeRelatedArrays { get; set; }
    public string? ConditionNote { get; set; }
}

public class AddMeasurementTestDto
{
    public long TestId { get; set; }
    public object Value { get; set; } = 0;
    public string? Note { get; set; }
}