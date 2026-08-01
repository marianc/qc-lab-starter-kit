using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface ITestsService
    {
        Task<List<TestDto>> GetAllTests();
        Task<bool> CheckCodeUniqueness(string code, long? id);
        Task<TestDto?> GetTest(long id);
        Task<List<TestEnumDto>> GetTestEnums(long id);
        Task<IdDto> AddTestEnum(long id, CreateTestEnumDto newEnum);
        Task ReorderTestEnums(long id, List<ReorderTestEnumDto> enumsData);
        Task UpdateTestEnum(long id, long enumId, UpdateTestEnumDto enumData);
        Task DeleteTestEnum(long id, long enumId);
        Task<IdDto> CreateTest(CreateTestDto newTest);
        Task ReorderTests(List<ReorderTestDto> testsData);
        Task UpdateTest(long id, UpdateTestDto testData);
        Task ToggleObsolete(long id, ToggleObsoleteDto dto);
        Task<List<long>> GetCertifiedTestIds();
    }
}