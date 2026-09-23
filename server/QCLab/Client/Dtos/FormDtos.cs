using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class FormDto
{
    public long Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? CustomNav { get; set; }
    public bool IsCustomized { get; set; }
    public bool IsCancelled { get; set; }
    public bool IsSubmitted { get; set; }
    public bool IsValidated { get; set; }
    public List<FormParamSimpleDto> FormParams { get; set; } = new();
}

public class FormParamSimpleDto
{
    public long TestId { get; set; }
    public bool IsCalculated { get; set; }
    [RegularExpression(@"^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$" , ErrorMessage = "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores.")]
    public string? CodeRelatedArrays { get; set; }
    public bool IsRequired { get; set; }
    public decimal? DefaultValue { get; set; }
    public long NrOrd { get; set; }
    public string? ConditionNote { get; set; }
}

public class FormDetailDto
{
    public long Id { get; set; }
    public long FormGroupId { get; set; }
    public string? Version { get; set; }
    public int DaysActiveForEditing { get; set; }
    public string? CustomNav { get; set; }
    public bool IsCustomized { get; set; }
    public bool IsSubmitted { get; set; }
    public long? UserSubmittedId { get; set; }
    public string? UserSubmittedTag { get; set; }
    public DateTime? DateSubmitted { get; set; }
    public string? CommentsSubmitted { get; set; }
    public bool IsValidated { get; set; }
    public string? UserValidatedTag { get; set; }
    public DateTime? DateValidated { get; set; }
    public string? CommentsValidated { get; set; }
    public bool IsCancelled { get; set; }
    public string? UserCancelledTag { get; set; }
    public DateTime? DateCancelled { get; set; }
    public string? CommentsCancelled { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class CreateFormDto
{
    public long FormGroupId { get; set; }
    public string? Version { get; set; }
    public int DaysActiveForEditing { get; set; } = 10;
    public string? CustomNav { get; set; }
    public bool IsCustomized { get; set; }
    public long SubmittedUserId { get; set; }
    public DateTime? SubmittedDate { get; set; }
}

public class UpdateFormDto
{
    public long FormGroupId { get; set; }
    public string? Version { get; set; }
    public int DaysActiveForEditing { get; set; }
    public string? CustomNav { get; set; }
    public bool IsCustomized { get; set; }
    public long UserId { get; set; }
}

public class FormConditionEvalDto
{
    public long Id { get; set; }
    public long FormId { get; set; }
    public long TestId { get; set; }
    public decimal Value { get; set; }
    public decimal? Result { get; set; }
    public decimal ExpectedResult { get; set; }
    public bool IsMatch { get; set; }
    public string? Note { get; set; }
}

public class FormParamDto
{
    public long FormId { get; set; }
    public long TestId { get; set; }
    public bool IsCalculated { get; set; }

    [FormulaValidator]
    public string? Formula { get; set; }

    [RegularExpression(@"^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$" , ErrorMessage = "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores.")]
    public string? CodeRelatedArrays { get; set; }
    public bool IsRequired { get; set; }
    public decimal? DefaultValue { get; set; }
    public long NrOrd { get; set; }
    public long NrOrdCalc { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public long TypeId { get; set; }
    public bool IsArray { get; set; }
    public string Dependencies { get; set; } = string.Empty;
    public bool IsFormSubmitted { get; set; }

    // Condition validation fields
    public bool HasCondition { get; set; }
    public string? Condition { get; set; }
    public string? ConditionNote { get; set; }
    public List<FormConditionEvalDto> Evals { get; set; } = new();
}

public class ReorderFormParamDto
{
    public long TestId { get; set; }
    public long NrOrd { get; set; }
}

public class BatchUpdateFormParamDto
{
    public long TestId { get; set; }
    public bool IsCalculated { get; set; }
    public string? Formula { get; set; }
    [RegularExpression(@"^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$" , ErrorMessage = "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores.")]
    public string? CodeRelatedArrays { get; set; }
    public bool IsRequired { get; set; }
    public decimal? DefaultValue { get; set; }
    public long NrOrd { get; set; }
    public long NrOrdCalc { get; set; }

    // Condition validation fields
    public bool HasCondition { get; set; }
    public string? Condition { get; set; }
    public string? ConditionNote { get; set; }
    public List<FormConditionEvalDto> Evals { get; set; } = new();
}

public class CreateFormParamDto : BatchUpdateFormParamDto { }

public class UpdateFormParamDto : BatchUpdateFormParamDto { }

public class FormActionDto
{
    public long UserId { get; set; }
    public string? CommentsValidated { get; set; }
    public string? CommentsCancelled { get; set; }
}
