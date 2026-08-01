using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;
using System.Web;

namespace QCLab.Client.Services;

public class ClientReceptionsService(HttpClient httpClient) : IReceptionsService
{
    public async Task<List<ApplicableFormDto>> GetApplicableForms(long reception_id)
    {
        var result = await httpClient.GetFromJsonAsync<List<ApplicableFormDto>>($"/api/receptions/{reception_id}/applicable_forms");
        return result ?? new List<ApplicableFormDto>();
    }

    public async Task<PaginatedReceptionsDto> GetAllReceptions(
        int page,
        int per_page,
        long? user_id,
        long? submitted_by,
        long? type_id,
        long? material_id,
        string? report_submitted,
        string? status,
        int? submission_year,
        int? submission_month)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        query["page"] = page.ToString();
        query["per_page"] = per_page.ToString();
        if (user_id.HasValue) query["user_id"] = user_id.Value.ToString();
        if (submitted_by.HasValue) query["submitted_by"] = submitted_by.Value.ToString();
        if (type_id.HasValue) query["type_id"] = type_id.Value.ToString();
        if (material_id.HasValue) query["material_id"] = material_id.Value.ToString();
        if (!string.IsNullOrEmpty(report_submitted)) query["report_submitted"] = report_submitted;
        if (!string.IsNullOrEmpty(status)) query["status"] = status;
        if (submission_year.HasValue) query["submission_year"] = submission_year.Value.ToString();
        if (submission_month.HasValue) query["submission_month"] = submission_month.Value.ToString();

        var result = await httpClient.GetFromJsonAsync<PaginatedReceptionsDto>($"/api/receptions?{query}");
        return result ?? new PaginatedReceptionsDto();
    }

    public Task<ReceptionDetailDto?> GetReception(long reception_id) =>
        httpClient.GetFromJsonAsync<ReceptionDetailDto>($"/api/receptions/{reception_id}");

    public async Task<IdDto> CreateReception(CreateReceptionDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/receptions", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateReception(long reception_id, UpdateReceptionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task<List<ReceptionTestDto>> GetReceptionTests(long reception_id)
    {
        var result = await httpClient.GetFromJsonAsync<List<ReceptionTestDto>>($"/api/receptions/{reception_id}/tests");
        return result ?? new List<ReceptionTestDto>();
    }

    public async Task UpdateReceptionTests(long reception_id, UpdateReceptionTestsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}/tests", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task SubmitReception(long reception_id, SubmitReceptionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}/submit", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task CancelSubmission(long reception_id)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}/cancel_submission", new { });
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task ReceiveReception(long reception_id, ReceiveReceptionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}/receive", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task RejectReception(long reception_id, RejectReceptionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/receptions/{reception_id}/reject", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task<List<ReportSummaryDto>> GetReceptionReports(long reception_id)
    {
        var result = await httpClient.GetFromJsonAsync<List<ReportSummaryDto>>($"/api/receptions/{reception_id}/reports");
        return result ?? new List<ReportSummaryDto>();
    }

    public async Task<IdDto> CreateReport(long reception_id, CreateReportDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync($"/api/receptions/{reception_id}/create_report", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task<bool> CheckReportConflict(long reception_id)
    {
        var result = await httpClient.GetFromJsonAsync<Dictionary<string, bool>>($"/api/receptions/{reception_id}/check_report_conflict");
        return result != null && result.ContainsKey("conflict") && result["conflict"];
    }

    public async Task<List<MeasurementTestDetailDto>> GetReceptionMeasurementTests(long reception_id) =>
        (await httpClient.GetFromJsonAsync<List<MeasurementTestDetailDto>>($"/api/receptions/{reception_id}/measurement_tests")) ?? new List<MeasurementTestDetailDto>();

    public async Task<List<MeasurementParamDetailDto>> GetReceptionMeasurementParams(long reception_id) =>
        (await httpClient.GetFromJsonAsync<List<MeasurementParamDetailDto>>($"/api/receptions/{reception_id}/measurement_params")) ?? new List<MeasurementParamDetailDto>();

    public async Task<PreviewReportDto> GetPreviewReport(long reception_id) =>
        (await httpClient.GetFromJsonAsync<PreviewReportDto>($"/api/receptions/{reception_id}/preview"))!;

    public async Task<ExpressCertificateResultDto> SubmitExpressCertificate(long reception_id, ExpressCertificateDto dto)
    {
        var response = await httpClient.PostAsJsonAsync($"/api/receptions/{reception_id}/submit_express_certificate", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
        return (await response.Content.ReadFromJsonAsync<ExpressCertificateResultDto>())!;
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
