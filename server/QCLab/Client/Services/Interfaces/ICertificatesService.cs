using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface ICertificatesService
    {
        Task<PaginatedCertificatesDto> GetAllCertificates(
            int page,
            int pageSize,
            bool isQCPersonnel,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null);
        Task<CertificateDetailDto?> GetCertificate(long id);
        Task<CertificateDetailDto?> GenerateCertificate(GenerateCertificateDto dto);
        Task UpdateCertificate(long id, UpdateCertificateDto dto);
        Task RefreshTests(long id);
        Task<CertificateAnalysisDto> AnalyzeResults(long id);
        Task<CertificateAnalysisDto> AnalyzeInFlightResults(long specId, long controlCodeId, List<(long MeasurementId, bool HasForm, long TestId, decimal Value, int Idx, decimal? UncertaintyValue, decimal? CoverageFactorK)> currentReportTestRows);
        Task<bool> HasExistingValidCertificates(long id);
        Task SubmitCertificate(long id, CertificateActionDto dto);
        Task CancelCertificate(long id, CertificateActionDto dto);
        Task DeleteCertificate(long id, long userId);
        Task<byte[]?> GetCertificatePdf(long id);
        Task<byte[]?> ExportCertificatesExcel(
            bool isQCPersonnel,
            long? materialId = null,
            int? submissionYear = null,
            int? submissionMonth = null,
            int? loadedPages = null,
            int pageSize = 15,
            IHttpClientFactory? clientFactory = null);
    }
}