using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface IEquipmentsService
{
    Task<List<EquipmentDto>> GetAllEquipments();
    Task<EquipmentDto?> GetEquipment(long id);
    Task<IdDto> CreateEquipment(CreateEquipmentDto dto);
    Task UpdateEquipment(long id, UpdateEquipmentDto dto);
    Task<List<EquipmentCalibrationDto>> GetEquipmentCalibrations(long equipmentId);
    Task<IdDto> AddEquipmentCalibration(long equipmentId, CreateEquipmentCalibrationDto dto);
    Task UpdateEquipmentCalibration(long calibrationId, CreateEquipmentCalibrationDto dto);
    Task<List<EquipmentStatusDto>> GetEquipmentStatuses();
    Task<List<EquipmentCalibrationStatusDto>> GetEquipmentCalibrationStatuses();
}
