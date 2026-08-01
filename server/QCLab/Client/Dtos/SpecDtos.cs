using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class SpecDto
{
    public long Id { get; set; }
    public long MaterialId { get; set; }
    public string MaterialName { get; set; } = string.Empty;
    public string? NormName { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public DateTime? DateCancelled { get; set; }
    public bool IsSubmitted { get; set; }
    public long? SpecReplacedId { get; set; }
    public string Status { get; set; } = "Draft";
    // For detailed view
    public string? UserSubmittedTag { get; set; }
    public string? UserCancelledTag { get; set; }
    public string? CommentsSubmitted { get; set; }
    public string? CommentsCancelled { get; set; }
    public List<SpecTestDto>? Tests { get; set; }
    public List<long>? ApplicableTests { get; set; }
    public List<long>? CertifiedTests { get; set; }
}

public class SpecTestDto
{
    [Required]
    [Range(1, long.MaxValue, ErrorMessage = "Test Id must be selected")]
    public long TestId { get; set; }
    public string TestName { get; set; } = string.Empty;
    public string? UnitName { get; set; }
    public long NrOrd { get; set; }

    [Required]
    [Range(0, int.MaxValue, ErrorMessage = "Frequency must be at least 0")]
    public int TestFrequency { get; set; }

    [Required]
    [ConditionFormula]
    public string Condition { get; set; } = string.Empty;

    [Required(ErrorMessage = "Note is required")]
    public string Note { get; set; } = string.Empty;

    [NotEmptyCollection(ErrorMessage = "At least one evaluation test is required")]
    public List<SpecTestEvalDto> Evals { get; set; } = new();
}

public class SpecTestEvalDto
{
    public long Id { get; set; }
    
    [Required]
    public decimal Value { get; set; }

    public decimal? Result { get; set; }

    [Required]
    public decimal ExpectedResult { get; set; }

    public bool IsMatch { get; set; }

    public string? Note { get; set; }
}

public class CreateSpecDto
{
    public long MaterialId { get; set; }
    public long UserId { get; set; }
    public string? CommentsSubmitted { get; set; }
}

public class UpdateSpecDto
{
    public long MaterialId { get; set; }
    public long UserId { get; set; }
    public string? CommentsSubmitted { get; set; }
}

public class CreateSpecTestDto
{
    [Required]
    public long TestId { get; set; }

    [Required]
    [Range(0, int.MaxValue, ErrorMessage = "Frequency must be at least 0")]
    public int TestFrequency { get; set; }

    [Required]
    [ConditionFormula]
    public string Condition { get; set; } = string.Empty;

    [Required(ErrorMessage = "Note is required")]
    public string Note { get; set; } = string.Empty;

    [NotEmptyCollection(ErrorMessage = "At least one evaluation test is required")]
    public List<SpecTestEvalDto> Evals { get; set; } = new();
}

public class UpdateSpecTestDto
{
    [Required]
    [Range(0, int.MaxValue, ErrorMessage = "Frequency must be at least 0")]
    public int TestFrequency { get; set; }

    [Required]
    [ConditionFormula]
    public string Condition { get; set; } = string.Empty;

    [Required(ErrorMessage = "Note is required")]
    public string Note { get; set; } = string.Empty;

    [NotEmptyCollection(ErrorMessage = "At least one evaluation test is required")]
    public List<SpecTestEvalDto> Evals { get; set; } = new();
}

public class SpecActionDto
{
    public long UserId { get; set; }
    public string? CommentsSubmitted { get; set; } // for submit
    public string? CommentsCancelled { get; set; } // for cancel
}
