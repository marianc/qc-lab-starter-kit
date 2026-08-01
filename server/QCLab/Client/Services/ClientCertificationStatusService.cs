using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientCertificationStatusService(HttpClient httpClient) : ICertificationStatusService
{
    public Task<List<CertificationStatusDto>> GetCertificationStatus() =>
        httpClient.GetFromJsonAsync<List<CertificationStatusDto>>("/api/certification_status")!;
}
