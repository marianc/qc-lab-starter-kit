using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class MaterialDto
{
    public long Id { get; set; }

    [Unique("Material", ErrorMessage = "Material name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Unique("Material", ErrorMessage = "Material code is already in use.")]
    [StringLength(5, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 5 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
    public long? NormId { get; set; }
    public string? NormName { get; set; }
    public bool IsProduct { get; set; }
    public bool IsRawMaterial { get; set; }
    public bool IsReagent { get; set; }
    public bool IsObsolete { get; set; }
    public DateTime DateCreated { get; set; }
    public DateTime? DateObsolete { get; set; }
    public string? CommentsObsolete { get; set; }
}

public class CreateMaterialDto
{
    [Unique("Material", ErrorMessage = "Material name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Unique("Material", ErrorMessage = "Material code is already in use.")]
    [StringLength(5, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 5 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
    public long? NormId { get; set; }
    public bool IsProduct { get; set; }
    public bool IsRawMaterial { get; set; }
    public bool IsReagent { get; set; }
    public bool IsObsolete { get; set; }
}

public class UpdateMaterialDto : CreateMaterialDto { }

public class MaterialTestDto
{
    public long Id { get; set; }
    public required string Name { get; set; }
    public required string Code { get; set; }
    public long TypeId { get; set; }
    public bool IsArray { get; set; }
    public string TypeName { get; set; } = string.Empty;
}

public class UpdateMaterialTestsDto
{
    public required List<long> TestIds { get; set; }
}

public class MaterialControlCodeDto
{
    public long Id { get; set; }
    public required string Code { get; set; }
}
