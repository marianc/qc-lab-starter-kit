namespace QCLab.Client.Dtos;

public class ReceptionDto
{
    public long Id { get; set; }
    public long TypeId { get; set; }
    public string ReceptionTypeName { get; set; } = string.Empty;
    public long? ControlCodeId { get; set; }
    public string? MaterialName { get; set; }
    public string? ControlCodeName { get; set; }
    public string? CommentsSubmitted { get; set; }
    public long? CategoryId { get; set; }
    public string? CategoryName { get; set; }
    public bool IsSubmitted { get; set; }
    public long? UserSubmittedId { get; set; }
    public string? UserSubmittedTag { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public bool IsReceived { get; set; }
    public long? UserReceivedId { get; set; }
    public string? UserReceivedTag { get; set; }
    public DateTime? DateReceived { get; set; }
    public string? CommentsReceived { get; set; }
    public bool IsRejected { get; set; }
    public long? UserRejectedId { get; set; }
    public string? UserRejectedTag { get; set; }
    public DateTime? DateRejected { get; set; }
    public string? CommentsRejected { get; set; }
    public bool ReportSubmitted { get; set; }
    public string Status { get; set; } = "Pending";
}

public class ReceptionDetailDto : ReceptionDto
{
    public long? MaterialId { get; set; }
    public List<long> ApplicableForms { get; set; } = new List<long>();
    public List<long> ApplicableTests { get; set; } = new List<long>();
    public List<long>? ReceptionTests { get; set; }
}

public class CreateReceptionDto
{
    public long TypeId { get; set; }
    public long? ControlCodeId { get; set; }
    public long? CategoryId { get; set; }
    public string? CommentsSubmitted { get; set; }
    public string? MaterialName { get; set; }
    public long UserId { get; set; }
}

public class UpdateReceptionDto
{
    public long TypeId { get; set; }
    public long? ControlCodeId { get; set; }
    public long? CategoryId { get; set; }
    public string? CommentsSubmitted { get; set; }
    public string? MaterialName { get; set; }
    public long UserId { get; set; }
}

public class UpdateReceptionTestsDto
{
    public List<long> TestIds { get; set; } = new List<long>();
}

public class SubmitReceptionDto
{
    public long UserId { get; set; }
    public string? Comments { get; set; }
}

public class ReceiveReceptionDto
{
    public long UserId { get; set; }
    public string? Comments { get; set; }
}

public class RejectReceptionDto
{
    public long UserId { get; set; }
    public required string Reason { get; set; }
}

public class CreateReportDto
{
    public long UserId { get; set; }
    public string? Comments { get; set; }
}

public class ExpressCertificateDto
{
    public long UserId { get; set; }
    public string? Comments { get; set; }
}

public class ExpressCertificateResultDto
{
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
    public long? CertificateId { get; set; }
}

public class ReceptionTestDto
{
    public long Id { get; set; }
    public required string Name { get; set; }
}

public class ReportSummaryDto
{
    public long Id { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public string? UserSubmittedTag { get; set; }
    public string? CommentsSubmitted { get; set; }
    public long? ReportReplacedId { get; set; }
    public DateTime? DateCancelled { get; set; }
    public string? UserCancelledTag { get; set; }
    public string? CommentsCancelled { get; set; }
}

public class ApplicableFormDto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsCustomized { get; set; }
    public string? CustomNav { get; set; }
    public bool IsCancelled { get; set; }
    public bool IsSubmitted { get; set; }
    public bool IsValidated { get; set; }
}

public class CheckReportConflictDto
{
    public bool Conflict { get; set; }
}

public class PaginatedReceptionsDto
{
    public List<ReceptionDto> Receptions { get; set; } = new List<ReceptionDto>();
    public long TotalPages { get; set; }
    public int CurrentPage { get; set; }
    public long TotalCount { get; set; }
}
