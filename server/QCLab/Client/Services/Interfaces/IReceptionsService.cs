using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IReceptionsService
    {
        Task<List<ApplicableFormDto>> GetApplicableForms(long reception_id);
        Task<PaginatedReceptionsDto> GetAllReceptions(
            int page,
            int per_page,
            long? user_id,
            long? submitted_by,
            long? type_id,
            long? material_id,
            string? report_submitted,
            string? status,
            int? submission_year,
            int? submission_month);
        Task<ReceptionDetailDto?> GetReception(long reception_id);
        Task<IdDto> CreateReception(CreateReceptionDto dto);
        Task UpdateReception(long reception_id, UpdateReceptionDto dto);
        Task<List<ReceptionTestDto>> GetReceptionTests(long reception_id);
        Task UpdateReceptionTests(long reception_id, UpdateReceptionTestsDto dto);
        Task SubmitReception(long reception_id, SubmitReceptionDto dto);
        Task CancelSubmission(long reception_id);
        Task ReceiveReception(long reception_id, ReceiveReceptionDto dto);
        Task RejectReception(long reception_id, RejectReceptionDto dto);
        Task<List<ReportSummaryDto>> GetReceptionReports(long reception_id);
        Task<IdDto> CreateReport(long reception_id, CreateReportDto dto);
        Task<bool> CheckReportConflict(long reception_id);
        Task<List<MeasurementTestDetailDto>> GetReceptionMeasurementTests(long reception_id);
        Task<List<MeasurementParamDetailDto>> GetReceptionMeasurementParams(long reception_id);
        Task<PreviewReportDto> GetPreviewReport(long reception_id);
        Task<ExpressCertificateResultDto> SubmitExpressCertificate(long reception_id, ExpressCertificateDto dto);
    }
}