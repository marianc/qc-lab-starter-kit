using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IMeasurementsService
    {
        Task<MeasurementTestDetailDto?> GetMeasurementTest(long id);
        Task<MeasurementParamDetailDto?> GetMeasurementParam(long id);
        Task<IdDto> CreateMeasurement(CreateMeasurementDto dto);
        Task UpdateMeasurementTest(long id, UpdateMeasurementTestBulkDto dto);
        Task UpdateMeasurementParam(long id, UpdateMeasurementParamDto dto);
        Task DeleteMeasurement(long id);
        Task ToggleReported(long id, long userId);
        Task<List<TestEquipmentDto>> GetMeasurementEquipments(long id);
        Task UpdateMeasurementEquipments(long id, UpdateTestEquipmentsDto dto);
        Task<IdDto> AddMeasurementTest(long id, AddMeasurementTestDto dto);
    }
}