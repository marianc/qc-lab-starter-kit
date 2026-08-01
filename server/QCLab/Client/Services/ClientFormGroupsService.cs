using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientFormGroupsService(HttpClient httpClient) : IFormGroupsService
{
    public Task<List<FormGroupDto>> GetAllFormGroups() =>
        httpClient.GetFromJsonAsync<List<FormGroupDto>>("/api/form_groups")!;

    public Task<FormGroupDto?> GetFormGroup(long id) =>
        httpClient.GetFromJsonAsync<FormGroupDto>($"/api/form_groups/{id}");

    public async Task<IdDto> CreateFormGroup(CreateFormGroupDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/form_groups", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return await response.Content.ReadFromJsonAsync<IdDto>();
    }

    public async Task UpdateFormGroup(long id, UpdateFormGroupDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/form_groups/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task BulkUpdateFormGroups(List<UpdateFormGroupDto> dtos)
    {
        var response = await httpClient.PutAsJsonAsync("/api/form_groups", dtos);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task DeleteFormGroup(long id)
    {
        var response = await httpClient.DeleteAsync($"/api/form_groups/{id}");
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public Task<List<FormSummaryDto>> GetFormsByGroup(long id) =>
        httpClient.GetFromJsonAsync<List<FormSummaryDto>>($"/api/form_groups/{id}/forms")!;

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
