using System.ComponentModel.DataAnnotations;
using QCLab.Client.Dtos;

namespace QCLab.Client.Validation;

public class NotEmptyArrayAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        // This attribute was designed for the old structure.
        // For the new structure where Value is an object (potentially a List), 
        // we can check if it's a list and has elements.
        
        if (value is System.Collections.IEnumerable enumerable && !(value is string))
        {
            var enumerator = enumerable.GetEnumerator();
            if (!enumerator.MoveNext())
            {
                return new ValidationResult("At least one value is required for array tests.", new[] { validationContext.MemberName! });
            }
        }

        return ValidationResult.Success;
    }
}