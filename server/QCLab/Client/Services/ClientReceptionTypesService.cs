using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientReceptionTypesService(HttpClient httpClient) : IReceptionTypesService
{
    public Task<List<ReceptionTypeDto>> GetAllReceptionTypes() =>
        httpClient.GetFromJsonAsync<List<ReceptionTypeDto>>("/api/reception_types")!;
}
