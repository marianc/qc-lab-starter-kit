using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientControlCodesService(HttpClient httpClient) : IControlCodesService
{
    public async Task<List<ControlCodeDto>> GetAllControlCodes()
    {
        var result = await httpClient.GetFromJsonAsync<List<ControlCodeDto>>("/api/control_codes");
        return result ?? new List<ControlCodeDto>();
    }

    public async Task<List<ControlCodeSelectionDto>> GetControlCodesByMaterial(long material_id)
    {
        var result = await httpClient.GetFromJsonAsync<List<ControlCodeSelectionDto>>($"/api/control_codes/by_material/{material_id}");
        return result ?? new List<ControlCodeSelectionDto>();
    }

    public async Task<IdDto> CreateControlCode(CreateControlCodeDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/control_codes", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return await response.Content.ReadFromJsonAsync<IdDto>();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
