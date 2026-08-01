using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IUnitsService
    {
        Task<List<UnitDto>> GetAllUnits();
        Task<UnitDto?> GetUnit(long id);
        Task<IdDto> CreateUnit(CreateUnitDto dto);
        Task UpdateUnit(long id, UpdateUnitDto dto);
    }
}