using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientMaterialsService(HttpClient httpClient) : IMaterialsService
{
    public async Task<List<MaterialDto>> GetAllMaterials()
    {
        var result = await httpClient.GetFromJsonAsync<List<MaterialDto>>("/api/materials");
        return result ?? new List<MaterialDto>();
    }

    public async Task<List<MaterialDto>> GetMaterialsWithValidSpec()
    {
        var result = await httpClient.GetFromJsonAsync<List<MaterialDto>>("/api/materials/with_valid_spec");
        return result ?? new List<MaterialDto>();
    }

    public Task<MaterialDto?> GetMaterial(long id) =>
        httpClient.GetFromJsonAsync<MaterialDto>($"/api/materials/{id}");

    public async Task<IdDto> CreateMaterial(CreateMaterialDto dto)
    {
        var response = await httpClient.PostAsJsonAsync("/api/materials", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateMaterial(long id, UpdateMaterialDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/materials/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/materials/{id}/toggle_obsolete", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<List<MaterialTestDto>> GetMaterialTests(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MaterialTestDto>>($"/api/materials/{id}/tests");
        return result ?? new List<MaterialTestDto>();
    }

    public Task UpdateMaterialTests(long id, UpdateMaterialTestsDto dto) =>
        httpClient.PutAsJsonAsync($"/api/materials/{id}/tests", dto)!;

    public async Task<List<MaterialControlCodeDto>> GetControlCodes(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MaterialControlCodeDto>>($"/api/materials/{id}/control_codes");
        return result ?? new List<MaterialControlCodeDto>();
    }

    public async Task<List<MaterialControlCodeDto>> GetControlCodesForCertificate(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MaterialControlCodeDto>>($"/api/materials/{id}/control_codes_for_certificate");
        return result ?? new List<MaterialControlCodeDto>();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
