using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface ICertificationStatusService
    {
        Task<List<CertificationStatusDto>> GetCertificationStatus();
    }
}