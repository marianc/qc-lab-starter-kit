using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientValueTypesService(HttpClient httpClient) : IValueTypesService
{
    public Task<List<ValueTypeDto>> GetAllValueTypes() =>
        httpClient.GetFromJsonAsync<List<ValueTypeDto>>("/api/value_types")!;
}
