using System.ComponentModel.DataAnnotations;
using QCLab.Client.Dtos;

namespace QCLab.Client.Validation;

public class EnumListValidatorAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var test = validationContext.ObjectInstance as TestDto;
        if (test == null) return ValidationResult.Success;

        // Only validate if Type is Enum (4) and it is a new test (Id == 0)
        // Also check if EnumListString property exists or if we are validating that specific property
        
        if (test.TypeId == 4 && test.Id == 0)
        {
            var str = value as string;
            if (string.IsNullOrWhiteSpace(str))
            {
                return new ValidationResult("Enum List is required.", new[] { validationContext.MemberName! });
            }

            var items = str.Split(new[] { '\n', '\r', ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                           .Select(s => s.Trim())
                           .Where(s => !string.IsNullOrEmpty(s))
                           .Distinct()
                           .ToList();

            if (items.Count < 2)
            {
                return new ValidationResult("At least two items are required in the Enum List (separated by new line, comma or semicolon).", new[] { validationContext.MemberName! });
            }
        }

        return ValidationResult.Success;
    }
}
