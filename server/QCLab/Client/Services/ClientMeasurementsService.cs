using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientMeasurementsService(HttpClient httpClient) : IMeasurementsService
{
    public Task<MeasurementTestDetailDto?> GetMeasurementTest(long id) =>
        httpClient.GetFromJsonAsync<MeasurementTestDetailDto>($"/api/measurement_tests/{id}");

    public Task<MeasurementParamDetailDto?> GetMeasurementParam(long id) =>
        httpClient.GetFromJsonAsync<MeasurementParamDetailDto>($"/api/measurement_params/{id}");

    public async Task<IdDto> CreateMeasurement(CreateMeasurementDto dto)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/measurements", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateMeasurementTest(long id, UpdateMeasurementTestBulkDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurement_tests/{id}", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task UpdateMeasurementParam(long id, UpdateMeasurementParamDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurement_params/{id}", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task DeleteMeasurement(long id)
    {
        var response = await httpClient.DeleteAsync($"/api/measurements/{id}");
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task ToggleReported(long id, long userId)
    {
        var response = await httpClient.PutAsync($"/api/measurements/{id}/toggle_reported?userId={userId}", null);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task<List<TestEquipmentDto>> GetMeasurementEquipments(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<TestEquipmentDto>>($"/api/measurement_tests/{id}/equipments");
        return result ?? new List<TestEquipmentDto>();
    }

    public async Task UpdateMeasurementEquipments(long id, UpdateTestEquipmentsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurement_tests/{id}/equipments", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task<IdDto> AddMeasurementTest(long id, AddMeasurementTestDto dto)
    {
        var response = await httpClient.PostAsJsonAsync($"/api/measurements/{id}/tests", dto);
        return await response.Content.ReadFromJsonAsync<IdDto>() ?? new IdDto();
    }

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}