using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;
using System.Web;

namespace QCLab.Client.Services;

public class ClientTestsService(HttpClient httpClient) : ITestsService
{
    public async Task<List<TestDto>> GetAllTests()
    {
        var result = await httpClient.GetFromJsonAsync<List<TestDto>>("/api/tests");
        return result ?? new List<TestDto>();
    }

    public async Task<bool> CheckCodeUniqueness(string code, long? id)
    {
        var query = HttpUtility.ParseQueryString(string.Empty);
        query["code"] = code;
        if (id.HasValue) query["id"] = id.Value.ToString();
        var result = await httpClient.GetFromJsonAsync<Dictionary<string, bool>>($"/api/tests/check_code_uniqueness?{query}");
        return result != null && result.ContainsKey("is_unique") && result["is_unique"];
    }

    public Task<TestDto?> GetTest(long id) =>
        httpClient.GetFromJsonAsync<TestDto>($"/api/tests/{id}");

    public async Task<List<TestEnumDto>> GetTestEnums(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<TestEnumDto>>($"/api/tests/{id}/enums");
        return result ?? new List<TestEnumDto>();
    }

    public async Task<IdDto> AddTestEnum(long id, CreateTestEnumDto newEnum)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync($"/api/tests/{id}/enums", newEnum);
        response.EnsureSuccessStatusCode();
        // Assuming IdDto is returned. Original returned object.
        return await response.Content.ReadFromJsonAsync<IdDto>();
    }

    public Task ReorderTestEnums(long id, List<ReorderTestEnumDto> enumsData) =>
        httpClient.PutAsJsonAsync($"/api/tests/{id}/enums/reorder", enumsData)!;

    public Task UpdateTestEnum(long id, long enumId, UpdateTestEnumDto enumData) =>
        httpClient.PutAsJsonAsync($"/api/tests/{id}/enums/{enumId}", enumData)!;

    public Task DeleteTestEnum(long id, long enumId) =>
        httpClient.DeleteAsync($"/api/tests/{id}/enums/{enumId}");

    public async Task<IdDto> CreateTest(CreateTestDto newTest)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/tests", newTest);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public Task ReorderTests(List<ReorderTestDto> testsData) =>
        httpClient.PutAsJsonAsync("/api/tests/reorder", testsData)!;

    public async Task UpdateTest(long id, UpdateTestDto testData)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/tests/{id}", testData);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/tests/{id}/toggle_obsolete", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<List<long>> GetCertifiedTestIds()
    {
        var result = await httpClient.GetFromJsonAsync<List<long>>("/api/tests/certified_ids");
        return result ?? new List<long>();
    }

    public async Task<List<TestEquipmentDto>> GetTestEquipments(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<TestEquipmentDto>>($"/api/tests/{id}/equipments");
        return result ?? new List<TestEquipmentDto>();
    }

    public async Task UpdateTestEquipments(long id, UpdateTestEquipmentsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/tests/{id}/equipments", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
