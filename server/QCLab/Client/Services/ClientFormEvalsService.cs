using System.Net.Http.Json;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;

namespace QCLab.Client.Services;

public class ClientFormEvalsService : IFormEvalsService
{
    private readonly HttpClient _http;

    public ClientFormEvalsService(HttpClient http)
    {
        _http = http;
    }

    public async Task<List<FormEvalDto>> GetFormEvals(long formId)
    {
        return await _http.GetFromJsonAsync<List<FormEvalDto>>($"api/forms/{formId}/evals") ?? new();
    }

    public async Task<FormEvalDto?> GetFormEval(long id)
    {
        return await _http.GetFromJsonAsync<FormEvalDto>($"api/form-evals/{id}");
    }

    public async Task<IdDto> CreateFormEval(CreateFormEvalDto dto)
    {
        var response = await _http.PostAsJsonAsync("api/form-evals", dto);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<IdDto>() ?? new();
    }

    public async Task UpdateFormEval(long id, UpdateFormEvalDto dto)
    {
        var response = await _http.PutAsJsonAsync($"api/form-evals/{id}", dto);
        response.EnsureSuccessStatusCode();
    }

    public async Task DeleteFormEval(long id)
    {
        var response = await _http.DeleteAsync($"api/form-evals/{id}");
        response.EnsureSuccessStatusCode();
    }

    public async Task<FormEvalDto> CalculateFormEval(long id)
    {
        var response = await _http.PostAsync($"api/form-evals/{id}/calculate", null);
        response.EnsureSuccessStatusCode();
        return await response.Content.ReadFromJsonAsync<FormEvalDto>() ?? new();
    }
}
