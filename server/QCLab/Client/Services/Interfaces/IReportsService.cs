using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IReportsService
    {
        Task<PaginatedReportsDto> GetAllReports(
            int page,
            int pageSize,
            long? receptionTypeId = null,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null,
            bool isLabOrQcPers = false);
        Task<ReportDetailDto?> GetReport(long id);
        Task CancelReport(long id, CancelReportDto dto, string clientIp = "127.0.0.1");
        Task<bool> CheckReportConflict(long id);
        Task<byte[]?> ExportReportsExcel(
            long? receptionTypeId = null,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null,
            int? loadedPages = null,
            int pageSize = 15,
            bool isLabOrQcPers = false,
            IHttpClientFactory? clientFactory = null);
    }
}