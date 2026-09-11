using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface IReagentsService
{
    Task<List<ReagentDto>> GetAllReagents();
    Task<ReagentDto?> GetReagent(long id);
    Task<IdDto> CreateReagent(CreateReagentDto dto);
    Task UpdateReagent(long id, UpdateReagentDto dto);
    Task ToggleObsolete(long id, ToggleObsoleteDto dto);
    Task<List<ReagentLotDto>> GetReagentLots(long reagentId);
    Task<List<ReagentLotDto>> GetAllActiveReagentLots();
    Task<List<ReagentLotStatusDto>> GetReagentLotStatuses();
    Task<List<ReagentSupplierDto>> GetAllSuppliers();
    Task<IdDto> CreateSupplier(CreateReagentSupplierDto dto);
    Task<ReagentLotDto?> GetReagentLot(long controlCodeId);
    Task<IdDto> CreateSupplierLot(CreateSupplierLotDto dto);
    Task UpdateSupplierLot(long controlCodeId, UpdateSupplierLotDto dto);
    Task<IdDto> CreateProductionLot(CreateProductionLotDto dto);
    Task UpdateProductionLot(long controlCodeId, UpdateProductionLotDto dto);
}
