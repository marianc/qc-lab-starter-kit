using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class UnitDto
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is required.")]
    [Unique("Unit", ErrorMessage = "Unit name is already in use.")]
    [StringLength(50, ErrorMessage = "Name must be maximum 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
}

public class CreateUnitDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Unit", ErrorMessage = "Unit name is already in use.")]
    [StringLength(50, ErrorMessage = "Name must be maximum 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
}

public class UpdateUnitDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Unit", ErrorMessage = "Unit name is already in use.")]
    [StringLength(50, ErrorMessage = "Name must be maximum 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
}
