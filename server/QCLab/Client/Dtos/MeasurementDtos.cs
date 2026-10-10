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
    public long? UserUpdatedId { get; set; }
    public string? UserUpdatedTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime? DateUpdated { get; set; }
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
    public long? UserUpdatedId { get; set; }
    public string? UserUpdatedTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime? DateUpdated { get; set; }
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
    public long? UserUpdatedId { get; set; }
    public string? UserUpdatedTag { get; set; }
    public string? UserReportedTag { get; set; }
    public DateTime? DateUpdated { get; set; }

    [JsonIgnore]
    public List<MeasurementFormParamSchemaDto>? FormParamsSchema { get; set; }
    public Dictionary<string, object?> MeasurementData { get; set; } = new();
    public Dictionary<string, object?> CalculatedResults { get; set; } = new();
    public Dictionary<string, object?> ConditionPass { get; set; } = new();
    public Dictionary<string, CrmSelectionDto> CrmSelections { get; set; } = new();
}

public class CertifiedReferenceValueDto
{
    public required string MaterialName { get; set; }
    public required string LotCode { get; set; }
    public required string Source { get; set; }
    public decimal Value { get; set; }
    public long? CertificateId { get; set; }
    public long? ControlCodeId { get; set; }
    public long TestId { get; set; }
}

public class CrmSelectionDto
{
    public long? CertifiedReferenceCertificateId { get; set; }
    public long? CertifiedReferenceControlCodeId { get; set; }
    public string? LotCode { get; set; }
    public string? Source { get; set; }
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
    public Dictionary<string, CrmSelectionDto> CrmSelections { get; set; } = new();
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