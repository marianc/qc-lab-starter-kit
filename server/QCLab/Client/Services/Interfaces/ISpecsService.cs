using QCLab.Client.Dtos;


namespace QCLab.Client.Services.Interfaces
{
    public interface ISpecsService
    {
        Task<List<SpecDto>> GetAllSpecs(long? userId, bool isQCPersonnel);
        Task<SpecDto?> GetSpec(long id);
        Task<IdDto> CreateSpec(CreateSpecDto dto);
        Task UpdateSpec(long id, UpdateSpecDto dto);
        Task<SpecTestDto> AddSpecTest(long id, CreateSpecTestDto dto);
        Task UpdateSpecTest(long id, long testId, UpdateSpecTestDto dto);
        Task DeleteSpecTest(long id, long testId);
        Task DeleteSpec(long id);
        Task<SpecDto?> SubmitSpec(long id, SpecActionDto dto);
        Task CancelSpec(long id, SpecActionDto dto);
        Task<IdDto> DuplicateSpec(long id, SpecActionDto dto);
        Task ValidateCondition(string condition);
        Task<byte[]?> GetSpecPdf(long id);
    }
}