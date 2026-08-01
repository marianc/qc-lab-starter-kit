using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientCategoriesService(HttpClient httpClient) : ICategoriesService
{
    public async Task<List<CategoryDto>> GetAllCategories()
    {
        var result = await httpClient.GetFromJsonAsync<List<CategoryDto>>("/api/categories");
        return result ?? new List<CategoryDto>();
    }

    public Task<CategoryDto?> GetCategory(long id) =>
        httpClient.GetFromJsonAsync<CategoryDto>($"/api/categories/{id}");

    public async Task<IdDto> CreateCategory(CreateCategoryDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/categories", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateCategory(long id, UpdateCategoryDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/categories/{id}", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/categories/{id}/toggle_obsolete", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public async Task<List<CategoryTestDto>> GetCategoryTests(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<CategoryTestDto>>($"/api/categories/{id}/tests");
        return result ?? new List<CategoryTestDto>();
    }

    public async Task UpdateCategoryTests(long id, UpdateCategoryTestsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/categories/{id}/tests", dto);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
