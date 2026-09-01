namespace QCLab.Client.Dtos;

public class CertificateDto
{
    public long Id { get; set; }
    public string MaterialName { get; set; } = string.Empty;
    public string ControlCode { get; set; } = string.Empty;
    public bool IsConformingSpec { get; set; }
    public bool IsConformingUncertainty { get; set; } = true;
    public DateTime? DateSubmitted { get; set; }
    public long? CertificateReplacedId { get; set; }
    public DateTime? DateCancelled { get; set; }
    public bool IsCancelled { get; set; }
    public bool IsSubmitted { get; set; }
    public string Status { get; set; } = "Draft";
    public bool HasTestFromCancelledReport { get; set; }
}

public class PaginatedCertificatesDto
{
    public List<CertificateDto> Certificates { get; set; } = new();
    public long TotalCount { get; set; }
    public int PageSize { get; set; }
    public int CurrentPage { get; set; }
}

public class CertificateDetailDto : CertificateDto
{
    public long ReceptionId { get; set; }
    public long SpecId { get; set; }
    public long MaterialId { get; set; }
    public string? UserSubmittedTag { get; set; }
    public string? UserCancelledTag { get; set; }
    public string? CommentsSubmitted { get; set; }
    public string? CommentsCancelled { get; set; }
    public List<CertificateTestDto> Tests { get; set; } = new();
}

public class CertificateTestDto
{
    public long CertificateId { get; set; }
    public long ReportId { get; set; }
    public long MeasurementId { get; set; }
    public bool HasForm { get; set; }
    public long NrOrd { get; set; }
    public long TestId { get; set; }
    public long TypeId { get; set; }
    public string TypeName { get; set; } = string.Empty;
    public long Idx { get; set; }
    public decimal Value { get; set; }
    public decimal? UncertaintyValue { get; set; }
    public decimal? CoverageFactorK { get; set; }
    public string DisplayValue { get; set; } = string.Empty;
    public List<string> FormattedValues { get; set; } = new();
    public List<string> UncertaintyValues { get; set; } = new();
    public long TestCount { get; set; }
    public long TestFrequency { get; set; }
    public string NoteSpec { get; set; } = string.Empty;
    public bool IsConformingSpec { get; set; }
    public bool IsConformingUncertainty { get; set; } = true;
    public List<bool> ConformingResults { get; set; } = new();
    public List<bool> ConformingUncertaintyResults { get; set; } = new();
    public string TestName { get; set; } = string.Empty;
    public string? UnitName { get; set; }
    public bool ReportIsCancelled { get; set; }
}

public class GenerateCertificateDto
{
    public long MaterialId { get; set; }
    public long ControlCodeId { get; set; }
    public long UserId { get; set; }
}

public class UpdateCertificateDto
{
    public bool? IsConformingSpec { get; set; }
    public bool? IsConformingUncertainty { get; set; }
}

public class CertificateActionDto
{
    public long UserId { get; set; }
    public string? CommentsSubmitted { get; set; }
    public string? CommentsCancelled { get; set; }
}

public class CertificateAnalysisDto
{
    public string AnalysisResult { get; set; } = string.Empty;
    public bool IsConformingSpec { get; set; }
    public bool IsConformingUncertainty { get; set; } = true;
}

public class CertTestColumnDto
{
    public long TestId { get; set; }
    public string Name { get; set; } = string.Empty;
    public long NrOrd { get; set; }
}

public class CertReportTestValueDto
{
    public long TestId { get; set; }
    public List<string> Values { get; set; } = new();
}

public class CertExportRowDto
{
    public long CertificateId { get; set; }
    public string ControlCode { get; set; } = string.Empty;
    public string IsConforming { get; set; } = string.Empty;
    public string DateSubmitted { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public long MeasurementId { get; set; }
    public bool HasForm { get; set; }
    public List<CertReportTestValueDto> TestValues { get; set; } = new();
}

public class CertSheetExportDto
{
    public string SheetLabel { get; set; } = string.Empty;
    public string SheetTitle { get; set; } = string.Empty;
    public List<CertTestColumnDto> Tests { get; set; } = new();
    public List<CertExportRowDto> Rows { get; set; } = new();
}

public class QualityCertificatesExportRequestDto
{
    public List<CertSheetExportDto> Sheets { get; set; } = new();
}

