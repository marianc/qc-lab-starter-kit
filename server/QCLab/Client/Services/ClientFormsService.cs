using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;

using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientFormsService(HttpClient httpClient) : IFormsService
{
    public async Task<List<FormDto>> GetAllForms()
    {
        var result = await httpClient.GetFromJsonAsync<List<FormDto>>("/api/forms");
        return result ?? new List<FormDto>();
    }

    public Task<FormDetailDto?> GetForm(long id) =>
        httpClient.GetFromJsonAsync<FormDetailDto>($"/api/forms/{id}");

    public async Task<IdDto> CreateForm(CreateFormDto dto)
    {
        var response = await httpClient.PostAsJsonAsync("/api/forms", dto);
        await HandleResponseAsync(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateForm(long id, UpdateFormDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}", dto);
        await HandleResponseAsync(response);
    }

    public async Task<List<FormParamDto>> GetFormParams(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<FormParamDto>>($"/api/forms/{id}/params");
        return result ?? new List<FormParamDto>();
    }

    public async Task ReorderFormParams(long id, List<ReorderFormParamDto> reorderedParams)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/params/reorder", reorderedParams);
        await HandleResponseAsync(response);
    }

    public async Task BatchUpdateFormParams(long id, List<BatchUpdateFormParamDto> paramsData)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/params/batch-update", paramsData);
        await HandleResponseAsync(response);
    }

    public async Task<IdDto> AddFormParam(long id, CreateFormParamDto dto)
    {
        var response = await httpClient.PostAsJsonAsync($"/api/forms/{id}/params", dto);
        await HandleResponseAsync(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateFormParam(long id, long testId, UpdateFormParamDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/params/{testId}", dto);
        await HandleResponseAsync(response);
    }

    public async Task DeleteFormParam(long id, long testId)
    {
        var response = await httpClient.DeleteAsync($"/api/forms/{id}/params/{testId}");
        await HandleResponseAsync(response);
    }

    public async Task SubmitForm(long id, FormActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/submit", dto);
        await HandleResponseAsync(response);
    }

    public async Task ValidateForm(long id, FormActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/validate", dto);
        await HandleResponseAsync(response);
    }

    public async Task CancelForm(long id, FormActionDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/cancel", dto);
        await HandleResponseAsync(response);
    }

    public async Task ReactivateForm(long id)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/forms/{id}/reactivate", new { });
        await HandleResponseAsync(response);
    }

    public async Task<IdDto> DuplicateForm(long id, FormActionDto dto)
    {
        var response = await httpClient.PostAsJsonAsync($"/api/forms/{id}/duplicate", dto);
        await HandleResponseAsync(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task ValidateFormula(long formId, long testId, bool isCalculated, string? formula)
    {
        var url = $"/api/validate/formula?formId={formId}&testId={testId}&isCalculated={isCalculated}&formula={Uri.EscapeDataString(formula ?? "")}";
        var response = await httpClient.GetFromJsonAsync<FormulaValidationResult>(url);
        if (response != null && !response.valid)
        {
            throw new Exception(response.msg ?? "Invalid formula.");
        }
    }

    public async Task ValidateCondition(string condition)
    {
        var response = await httpClient.PostAsJsonAsync("/api/forms/validate-condition", condition);
        await HandleResponseAsync(response);
    }

    public Task<Dictionary<string, object>> EvaluateFormCalculations(long formId, Dictionary<string, object> measurementData)
    {
        throw new NotImplementedException("EvaluateFormCalculations is not implemented on the client.");
    }

    private async Task HandleResponseAsync(HttpResponseMessage response)
    {
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);

    private class FormulaValidationResult { public bool valid { get; set; } public string? msg { get; set; } }
}
