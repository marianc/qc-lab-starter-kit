using System.Collections;
using System.ComponentModel.DataAnnotations;

namespace QCLab.Client.Validation;

public class NotEmptyCollectionAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        if (value is IEnumerable list)
        {
            var enumerator = list.GetEnumerator();
            if (!enumerator.MoveNext())
            {
                return new ValidationResult(ErrorMessage ?? "The collection cannot be empty.", new[] { validationContext.MemberName! });
            }
            return ValidationResult.Success;
        }

        return ValidationResult.Success;
    }
}
