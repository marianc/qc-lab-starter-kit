using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;
using System.Web;

namespace QCLab.Client.Services;

public class ClientSpecsService(HttpClient httpClient) : ISpecsService
{
    public async Task<List<SpecDto>> GetAllSpecs(long? userId, bool isQCPersonnel)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        if (userId.HasValue) query["userId"] = userId.Value.ToString();
        query["isQCPersonnel"] = isQCPersonnel.ToString().ToLower();

        var result = await httpClient.GetFromJsonAsync<List<SpecDto>>($"/api/specs?{query}");
        return result ?? new List<SpecDto>();
    }

    public Task<SpecDto?> GetSpec(long id) =>
        httpClient.GetFromJsonAsync<SpecDto>($"/api/specs/{id}");

    public async Task<IdDto> CreateSpec(CreateSpecDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/specs", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateSpec(long id, UpdateSpecDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/specs/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<SpecTestDto> AddSpecTest(long id, CreateSpecTestDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync($"/api/specs/{id}/tests", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<SpecTestDto>())!;
    }

    public async Task UpdateSpecTest(long id, long testId, UpdateSpecTestDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/specs/{id}/tests/{testId}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task DeleteSpecTest(long id, long testId)
    {
        var response = await httpClient.DeleteAsync($"/api/specs/{id}/tests/{testId}");
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task DeleteSpec(long id)
    {
        var response = await httpClient.DeleteAsync($"/api/specs/{id}");
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<SpecDto?> SubmitSpec(long id, SpecActionDto dto)
    {
        HttpResponseMessage response = await httpClient.PutAsJsonAsync($"/api/specs/{id}/submit", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return await response.Content.ReadFromJsonAsync<SpecDto>();
    }

    public async Task CancelSpec(long id, SpecActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/specs/{id}/cancel", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<IdDto> DuplicateSpec(long id, SpecActionDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync($"/api/specs/{id}/duplicate", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task ValidateCondition(string condition)
    {
        var response = await httpClient.PostAsJsonAsync("/api/specs/validate-condition", condition);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<byte[]?> GetSpecPdf(long id)
    {
        var response = await httpClient.GetAsync($"/api/specs/{id}/pdf");
        if (!response.IsSuccessStatusCode) return null;
        return await response.Content.ReadAsByteArrayAsync();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}

