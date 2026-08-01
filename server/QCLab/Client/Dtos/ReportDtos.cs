namespace QCLab.Client.Dtos;

public class ReportDto
{
    public long Id { get; set; }
    public string? UserSubmittedTag { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public string ReceptionTypeName { get; set; } = string.Empty;
    public string? MaterialName { get; set; }
    public string? ControlCodeCategory { get; set; }
}

public class PaginatedReportsDto
{
    public List<ReportDto> Reports { get; set; } = new();
    public long TotalCount { get; set; }
    public int PageSize { get; set; }
    public int CurrentPage { get; set; }
}

public class ReportDetailDto
{
    public long Id { get; set; }
    public long ReceptionId { get; set; }
    public bool IsSubmitted { get; set; }
    public long? UserSubmittedId { get; set; }
    public string? UserSubmittedTag { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public string? CommentsSubmitted { get; set; }
    public long? ReportReplacedId { get; set; }
    public bool IsCancelled { get; set; }
    public long? UserCancelledId { get; set; }
    public string? UserCancelledTag { get; set; }
    public DateTime? DateCancelled { get; set; }
    public string? CommentsCancelled { get; set; }
    
    public string? MaterialName { get; set; }
    public string? ControlCode { get; set; }
    public string? ReceptionTypeName { get; set; }
    
    public List<ReportTestDto> Tests { get; set; } = new List<ReportTestDto>();
}

public class ReportTestDto
{
    public long MeasurementId { get; set; }
    public bool HasForm { get; set; }
    public long NrOrd { get; set; }
    public string TestName { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? UnitName { get; set; }
    public string Value { get; set; } = string.Empty; // Legacy display value
    public List<string> FormattedValues { get; set; } = new();
}

public class PreviewReportDto
{
    public long ReceptionId { get; set; }
    public string? MaterialName { get; set; }
    public string? ControlCodeName { get; set; }
    public string? ReceptionTypeName { get; set; }
    public string? UserSubmittedTag { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public string? CommentsSubmitted { get; set; }
    public bool IsCertification { get; set; }
    public long? ActiveSpecId { get; set; }
    public List<PreviewTestRowDto> Tests { get; set; } = new();
}

public class PreviewTestRowDto
{
    public long MeasurementId { get; set; }
    public bool HasForm { get; set; }
    public long NrOrd { get; set; }
    public long TestId { get; set; }
    public string TestName { get; set; } = string.Empty;
    public string TypeName { get; set; } = string.Empty;
    public string? UnitName { get; set; }
    public List<string> FormattedValues { get; set; } = new();
    public string? SpecNote { get; set; }
    public List<bool?> ConformingResults { get; set; } = new();
}

public class CancelReportDto
{
    public long UserId { get; set; }
    public string? CommentsCancelled { get; set; }
}

public class TestColumnDto
{
    public long TestId { get; set; }
    public string Name { get; set; } = string.Empty;
    public long NrOrd { get; set; }
}

public class ReportTestValueDto
{
    public long TestId { get; set; }
    public List<string> Values { get; set; } = new();
}

public class ReportExportRowDto
{
    public long ReportId { get; set; }
    public string DateSubmitted { get; set; } = string.Empty;
    public string? ControlCode { get; set; }
    public string? MaterialName { get; set; }
    public long MeasurementId { get; set; }
    public bool HasForm { get; set; }
    public List<ReportTestValueDto> TestValues { get; set; } = new();
}

public class SheetExportDto
{
    public string SheetLabel { get; set; } = string.Empty;
    public string SheetTitle { get; set; } = string.Empty;
    public bool IsCategory { get; set; }
    public List<TestColumnDto> Tests { get; set; } = new();
    public List<ReportExportRowDto> Rows { get; set; } = new();
}

public class TestingReportsExportRequestDto
{
    public List<SheetExportDto> Sheets { get; set; } = new();
}

