using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;
using System.Web;

namespace QCLab.Client.Services;

public class ClientReportsService(HttpClient httpClient) : IReportsService
{
    public async Task<PaginatedReportsDto> GetAllReports(
        int page,
        int pageSize,
        long userId,
        long? receptionTypeId = null,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        query["page"] = page.ToString();
        query["pageSize"] = pageSize.ToString();
        query["userId"] = userId.ToString();
        if (receptionTypeId.HasValue) query["receptionTypeId"] = receptionTypeId.Value.ToString();
        if (materialId.HasValue) query["materialId"] = materialId.Value.ToString();
        if (submissionYear.HasValue) query["submissionYear"] = submissionYear.Value.ToString();
        if (submissionMonth.HasValue) query["submissionMonth"] = submissionMonth.Value.ToString();

        var result = await httpClient.GetFromJsonAsync<PaginatedReportsDto>($"/api/reports?{query}");
        return result ?? new PaginatedReportsDto();
    }

    public Task<ReportDetailDto?> GetReport(long id) =>
        httpClient.GetFromJsonAsync<ReportDetailDto>($"/api/reports/{id}");

    public async Task CancelReport(long id, CancelReportDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/reports/{id}/cancel", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task<bool> CheckReportConflict(long id)
    {
        var result = await httpClient.GetFromJsonAsync<Dictionary<string, bool>>($"/api/reports/{id}/check_conflict");
        return result != null && result.ContainsKey("conflict") && result["conflict"];
    }

    public async Task<byte[]?> ExportReportsExcel(
        long? receptionTypeId = null,
        long? materialId = null,
        int? submissionYear = null,
        int? submissionMonth = null,
        int? loadedPages = null,
        int pageSize = 15,
        IHttpClientFactory? clientFactory = null)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        if (receptionTypeId.HasValue) query["receptionTypeId"] = receptionTypeId.Value.ToString();
        if (materialId.HasValue) query["materialId"] = materialId.Value.ToString();
        if (submissionYear.HasValue) query["submissionYear"] = submissionYear.Value.ToString();
        if (submissionMonth.HasValue) query["submissionMonth"] = submissionMonth.Value.ToString();
        if (loadedPages.HasValue) query["loadedPages"] = loadedPages.Value.ToString();
        query["pageSize"] = pageSize.ToString();

        var response = await httpClient.GetAsync($"/api/reports/export-excel?{query}");
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadAsByteArrayAsync();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
