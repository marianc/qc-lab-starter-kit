using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface ISopsService
{
    Task<List<SopDto>> GetSopsByNorm(long normId);
    Task<List<SopDto>> GetAllSops();
    Task<SopDto?> GetSop(long id);
    Task<IdDto> CreateSop(CreateSopWithVersionDto dto);
    Task<IdDto> CreateSopVersion(long sopId, UpdateSopVersionDto dto);
    Task UpdateSopVersion(long versionId, UpdateSopVersionDto dto);
    Task ActivateSopVersion(long versionId);
}
