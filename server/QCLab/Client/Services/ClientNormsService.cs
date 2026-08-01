using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientNormsService(HttpClient httpClient) : INormsService
{
    public async Task<List<NormDto>> GetAllNorms()
    {
        var result = await httpClient.GetFromJsonAsync<List<NormDto>>("/api/norms");
        return result ?? new List<NormDto>();
    }

    public Task<NormDto?> GetNorm(long id) =>
        httpClient.GetFromJsonAsync<NormDto>($"/api/norms/{id}");

    public async Task<IdDto> CreateNorm(CreateNormDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/norms", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateNorm(long id, UpdateNormDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/norms/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/norms/{id}/toggle_obsolete", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
