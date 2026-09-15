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
        var result = await httpClient.GetFromJsonAsync<List<TestEquipmentDto>>($"/api/measurements/{id}/equipments");
        return result ?? new List<TestEquipmentDto>();
    }

    public async Task<List<MeasurementSopVersionDto>> GetMeasurementSopVersions(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MeasurementSopVersionDto>>($"/api/measurements/{id}/sop_versions");
        return result ?? new List<MeasurementSopVersionDto>();
    }

    public async Task<List<MeasurementReagentLotDto>> GetMeasurementReagentLots(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MeasurementReagentLotDto>>($"/api/measurements/{id}/reagent_lots");
        return result ?? new List<MeasurementReagentLotDto>();
    }

    public async Task<List<MeasurementApplicableReagentLotDto>> GetMeasurementApplicableReagentLots(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MeasurementApplicableReagentLotDto>>($"/api/measurements/{id}/applicable_reagent_lots");
        return result ?? new List<MeasurementApplicableReagentLotDto>();
    }

    public async Task<List<MeasurementSopVersionDto>> GetMeasurementApplicableSopVersions(long id)
    {
        var result = await httpClient.GetFromJsonAsync<List<MeasurementSopVersionDto>>($"/api/measurements/{id}/applicable_sop_versions");
        return result ?? new List<MeasurementSopVersionDto>();
    }

    public async Task UpdateMeasurementEquipments(long id, UpdateTestEquipmentsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurement_tests/{id}/equipments", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task UpdateMeasurementSopVersions(long id, UpdateMeasurementSopVersionsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurements/{id}/sop_versions", dto);
        if (!response.IsSuccessStatusCode)
        {
            await HandleErrorResponse(response);
        }
    }

    public async Task UpdateMeasurementReagentLots(long id, UpdateMeasurementReagentLotsDto dto)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/measurements/{id}/reagent_lots", dto);
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