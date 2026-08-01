using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IReportsService
    {
        Task<PaginatedReportsDto> GetAllReports(
            int page,
            int pageSize,
            long userId,
            long? receptionTypeId = null,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null);
        Task<ReportDetailDto?> GetReport(long id);
        Task CancelReport(long id, CancelReportDto dto);
        Task<bool> CheckReportConflict(long id);
        Task<byte[]?> ExportReportsExcel(
            long? receptionTypeId = null,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null,
            int? loadedPages = null,
            int pageSize = 15,
            IHttpClientFactory? clientFactory = null);
    }
}