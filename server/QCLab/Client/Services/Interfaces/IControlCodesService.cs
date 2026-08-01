using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IControlCodesService
    {
        Task<List<ControlCodeDto>> GetAllControlCodes();
        Task<List<ControlCodeSelectionDto>> GetControlCodesByMaterial(long material_id);
        Task<IdDto> CreateControlCode(CreateControlCodeDto dto);
    }
}