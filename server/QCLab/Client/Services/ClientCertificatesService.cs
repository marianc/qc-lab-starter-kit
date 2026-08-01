using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;
using System.Web;

namespace QCLab.Client.Services;

public class ClientCertificatesService(HttpClient httpClient) : ICertificatesService
{
    public async Task<PaginatedCertificatesDto> GetAllCertificates(
        int page,
        int pageSize,
        bool isQCPersonnel,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        query["page"] = page.ToString();
        query["pageSize"] = pageSize.ToString();
        query["isQCPersonnel"] = isQCPersonnel.ToString().ToLower();
        if (materialId.HasValue) query["materialId"] = materialId.Value.ToString();
        if (submissionYear.HasValue) query["submissionYear"] = submissionYear.Value.ToString();
        if (submissionMonth.HasValue) query["submissionMonth"] = submissionMonth.Value.ToString();

        var result = await httpClient.GetFromJsonAsync<PaginatedCertificatesDto>($"/api/certificates?{query}");
        return result ?? new PaginatedCertificatesDto();
    }

    public Task<CertificateDetailDto?> GetCertificate(long id) =>
        httpClient.GetFromJsonAsync<CertificateDetailDto>($"/api/certificates/{id}");

    public async Task<CertificateDetailDto?> GenerateCertificate(GenerateCertificateDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/certificates/generate", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return await response.Content.ReadFromJsonAsync<CertificateDetailDto>();
    }

    public async Task UpdateCertificate(long id, UpdateCertificateDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/certificates/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task RefreshTests(long id)
    {
        var response = await httpClient.PutAsync($"/api/certificates/{id}/refresh_tests", null);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<bool> HasExistingValidCertificates(long id)
    {
        var response = await httpClient.GetFromJsonAsync<Dictionary<string, bool>>($"/api/certificates/{id}/has_existing");
        return response?["hasExisting"] ?? false;
    }

    public Task<CertificateAnalysisDto> AnalyzeResults(long id) =>
        httpClient.GetFromJsonAsync<CertificateAnalysisDto>($"/api/certificates/{id}/analyze_results")!;

    public Task<CertificateAnalysisDto> AnalyzeInFlightResults(long specId, long controlCodeId, List<(long MeasurementId, bool HasForm, long TestId, decimal Value, int Idx)> currentReportTestRows) =>
        throw new NotImplementedException();

    public async Task SubmitCertificate(long id, CertificateActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/certificates/{id}/submit", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task CancelCertificate(long id, CertificateActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/certificates/{id}/cancel", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task DeleteCertificate(long id)
    {
        var response = await httpClient.DeleteAsync($"/api/certificates/{id}");
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<byte[]?> GetCertificatePdf(long id)
    {
        var response = await httpClient.GetAsync($"/api/certificates/{id}/pdf");
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadAsByteArrayAsync();
    }

    public async Task<byte[]?> ExportCertificatesExcel(
        bool isQCPersonnel,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null,
        int? loadedPages = null,
        int pageSize = 15,
        IHttpClientFactory? clientFactory = null)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        query["isQCPersonnel"] = isQCPersonnel.ToString().ToLower();
        if (materialId.HasValue) query["materialId"] = materialId.Value.ToString();
        if (submissionYear.HasValue) query["submissionYear"] = submissionYear.Value.ToString();
        if (submissionMonth.HasValue) query["submissionMonth"] = submissionMonth.Value.ToString();
        if (loadedPages.HasValue) query["loadedPages"] = loadedPages.Value.ToString();
        query["pageSize"] = pageSize.ToString();

        var response = await httpClient.GetAsync($"/api/certificates/export-excel?{query}");
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadAsByteArrayAsync();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
