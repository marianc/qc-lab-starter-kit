using Microsoft.EntityFrameworkCore;
using QCLab.Models;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;

namespace QCLab.Services;

public class ServerCategoriesService : ICategoriesService
{
    private readonly QualityControlContext _context;

    public ServerCategoriesService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /categories
    public async Task<List<CategoryDto>> GetAllCategories()
    {
        var categories = await _context.Categories
            .Select(c => new CategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Code = c.Code,
                Description = c.Description,
                IsObsolete = c.IsObsolete,
                DateCreated = c.DateCreated,
                DateObsolete = c.DateObsolete,
                CommentsObsolete = c.CommentsObsolete
            })
            .ToListAsync();

        return categories;
    }

    // GET /categories/{id}
    public async Task<CategoryDto?> GetCategory(long id)
    {
        var category = await _context.Categories.FindAsync(id);

        if (category == null) return null;

        return (new CategoryDto
        {
            Id = category.Id,
            Name = category.Name,
            Code = category.Code,
            Description = category.Description,
            IsObsolete = category.IsObsolete,
            DateCreated = category.DateCreated,
            DateObsolete = category.DateObsolete,
            CommentsObsolete = category.CommentsObsolete
        });
    }

    // POST /categories
    public async Task<IdDto> CreateCategory(CreateCategoryDto dto)
    {
        var category = new Category
        {
            Name = dto.Name,
            Code = dto.Code,
            Description = dto.Description,
            DateCreated = DateTime.UtcNow
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();

        return new() { Id = category.Id };
    }

    // PUT /categories/{id}
    public async Task UpdateCategory(long id, UpdateCategoryDto dto)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) throw new ArgumentException("Category not found");

        category.Name = dto.Name;
        category.Code = dto.Code;
        category.Description = dto.Description;

        await _context.SaveChangesAsync();
    }

    // PUT /categories/{id}/toggle_obsolete
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) throw new ArgumentException("Category not found");

        category.IsObsolete = dto.IsObsolete;
        category.DateObsolete = dto.IsObsolete ? DateTime.UtcNow : null;
        category.CommentsObsolete = dto.IsObsolete ? dto.Comments : null;
        await _context.SaveChangesAsync();
    }

    // GET /categories/{id}/tests
    public async Task<List<CategoryTestDto>> GetCategoryTests(long id)
    {
        var tests = await _context.Categories
            .Where(c => c.Id == id)
            .SelectMany(c => c.Tests)
            .Where(t => !t.IsParam)
            .Include(t => t.Type)
            .Select(t => new CategoryTestDto
            {
                Id = t.Id,
                Name = t.Name,
                Code = t.Code,
                TypeId = t.TypeId,
                IsArray = t.IsArray,
                TypeName = t.Type.Name
            })
            .ToListAsync();

        return tests;
    }

    // PUT /categories/{id}/tests
    public async Task UpdateCategoryTests(long id, UpdateCategoryTestsDto dto)
    {
        var category = await _context.Categories.Include(c => c.Tests).FirstOrDefaultAsync(c => c.Id == id);
        if (category == null) throw new ArgumentException("Category not found");

        category.Tests.Clear();

        if (dto.TestIds != null && dto.TestIds.Count > 0)
        {
            var tests = await _context.Tests.Where(t => dto.TestIds.Contains(t.Id)).ToListAsync();
            foreach (var t in tests) category.Tests.Add(t);
        }

        await _context.SaveChangesAsync();
    }
}
