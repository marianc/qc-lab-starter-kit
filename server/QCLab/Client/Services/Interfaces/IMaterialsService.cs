using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IMaterialsService
    {
        Task<List<MaterialDto>> GetAllMaterials(bool isLabOrQcPers);
        Task<List<MaterialDto>> GetMaterialsWithValidSpec(bool isLabOrQcPers);
        Task<MaterialDto?> GetMaterial(long id, bool isLabOrQcPers);
        Task<IdDto> CreateMaterial(CreateMaterialDto dto);
        Task UpdateMaterial(long id, UpdateMaterialDto dto);
        Task ToggleObsolete(long id, ToggleObsoleteDto dto);
        Task<List<MaterialTestDto>> GetMaterialTests(long id);
        Task UpdateMaterialTests(long id, UpdateMaterialTestsDto dto);
        Task<List<MaterialControlCodeDto>> GetControlCodes(long id);
        Task<List<MaterialControlCodeDto>> GetControlCodesForCertificate(long id);
    }
}