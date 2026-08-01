using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientUnitsService(HttpClient httpClient) : IUnitsService
{
    public async Task<List<UnitDto>> GetAllUnits()
    {
        var result = await httpClient.GetFromJsonAsync<List<UnitDto>>("/api/units");
        return result ?? new List<UnitDto>();
    }

    public Task<UnitDto?> GetUnit(long id) =>
        httpClient.GetFromJsonAsync<UnitDto>($"/api/units/{id}");

    public async Task<IdDto> CreateUnit(CreateUnitDto dto)
    {
        var response = await httpClient.PostAsJsonAsync("/api/units", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateUnit(long id, UpdateUnitDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/units/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
