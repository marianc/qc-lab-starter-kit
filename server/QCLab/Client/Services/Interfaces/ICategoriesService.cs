using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface ICategoriesService
    {
        Task<List<CategoryDto>> GetAllCategories();
        Task<CategoryDto?> GetCategory(long id);
        Task<IdDto> CreateCategory(CreateCategoryDto dto);
        Task UpdateCategory(long id, UpdateCategoryDto dto);
        Task ToggleObsolete(long id, ToggleObsoleteDto dto);
        Task<List<CategoryTestDto>> GetCategoryTests(long id);
        Task UpdateCategoryTests(long id, UpdateCategoryTestsDto dto);
    }
}