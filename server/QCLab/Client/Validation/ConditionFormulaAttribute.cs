using System.ComponentModel.DataAnnotations;

namespace QCLab.Client.Validation;

public class ConditionFormulaAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        string? condition = value as string;
        if (string.IsNullOrWhiteSpace(condition))
        {
            return new ValidationResult("Condition is required.", new[] { validationContext.MemberName! });
        }

        // Formula validation is handled on the server.
        // On the client, we allow it to pass through to avoid dependency on QCFormula library.
        return ValidationResult.Success;
    }
}