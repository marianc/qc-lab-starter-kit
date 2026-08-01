using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class NormDto
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is required.")]
    [Unique("Norm", ErrorMessage = "Norm name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
    public bool IsObsolete { get; set; }
    public DateTime DateCreated { get; set; }
    public DateTime? DateObsolete { get; set; }
    public string? CommentsObsolete { get; set; }
}

public class CreateNormDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Norm", ErrorMessage = "Norm name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
}

public class UpdateNormDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Norm", ErrorMessage = "Norm name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }
}
