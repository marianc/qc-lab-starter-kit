using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class SopDto
{
    public long Id { get; set; }
    public required string DocCode { get; set; }
    public required string Title { get; set; }
    public long? NormId { get; set; }
    public DateTime DateCreated { get; set; }
    public List<SopVersionDto> Versions { get; set; } = new();
}

public class SopVersionDto
{
    public long Id { get; set; }
    public long SopId { get; set; }
    public required string VersionNumber { get; set; }
    public string? ExternalEdmsId { get; set; }
    public bool IsActive { get; set; }
    public DateTime DateActivated { get; set; }
    public string? Comments { get; set; }
}

public class CreateSopWithVersionDto
{
    [Required(ErrorMessage = "Doc code is required.")]
    [StringLength(50, ErrorMessage = "Doc code cannot exceed 50 characters.")]
    public required string DocCode { get; set; }

    [Required(ErrorMessage = "Title is required.")]
    [StringLength(150, ErrorMessage = "Title cannot exceed 150 characters.")]
    public required string Title { get; set; }

    public long? NormId { get; set; }

    [Required(ErrorMessage = "Version number is required.")]
    [StringLength(20, ErrorMessage = "Version number cannot exceed 20 characters.")]
    public required string VersionNumber { get; set; }

    public string? ExternalEdmsId { get; set; }
    public string? Comments { get; set; }
}

public class UpdateSopVersionDto
{
    [Required(ErrorMessage = "Version number is required.")]
    [StringLength(20, ErrorMessage = "Version number cannot exceed 20 characters.")]
    public required string VersionNumber { get; set; }

    public string? ExternalEdmsId { get; set; }
    public string? Comments { get; set; }
}
