using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class CategoryDto
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is required.")]
    [Unique("Category", ErrorMessage = "Category name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "Code is required.")]
    [Unique("Category", ErrorMessage = "Category code is already in use.")]
    [StringLength(3, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 3 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
    public bool IsObsolete { get; set; }
    public DateTime DateCreated { get; set; }
    public DateTime? DateObsolete { get; set; }
    public string? CommentsObsolete { get; set; }
}

public class CreateCategoryDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Category", ErrorMessage = "Category name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "Code is required.")]
    [Unique("Category", ErrorMessage = "Category code is already in use.")]
    [StringLength(3, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 3 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
}

public class UpdateCategoryDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Category", ErrorMessage = "Category name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "Code is required.")]
    [Unique("Category", ErrorMessage = "Category code is already in use.")]
    [StringLength(3, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 3 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
}

public class CategoryTestDto
{
    public long Id { get; set; }
    public required string Name { get; set; }
    public required string Code { get; set; }
    public long TypeId { get; set; }
    public bool IsArray { get; set; }
    public string TypeName { get; set; } = string.Empty;
}

public class UpdateCategoryTestsDto
{
    public required List<long> TestIds { get; set; }
}
