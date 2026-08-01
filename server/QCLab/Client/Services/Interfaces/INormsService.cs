using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface INormsService
    {
        Task<List<NormDto>> GetAllNorms();
        Task<NormDto?> GetNorm(long id);
        Task<IdDto> CreateNorm(CreateNormDto dto);
        Task UpdateNorm(long id, UpdateNormDto dto);
        Task ToggleObsolete(long id, ToggleObsoleteDto dto);
    }
}