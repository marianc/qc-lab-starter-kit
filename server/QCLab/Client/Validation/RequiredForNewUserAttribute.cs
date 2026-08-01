using System.ComponentModel.DataAnnotations;

namespace QCLab.Client.Validation;

public class RequiredForNewUserAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        // We need to access the Id property of the object being validated
        var idProperty = validationContext.ObjectType.GetProperty("Id");
        if (idProperty != null)
        {
            var idValue = (long?)idProperty.GetValue(validationContext.ObjectInstance);
            
            // If it's a new user (Id is null or 0), the field is required
            if ((idValue == null || idValue == 0) && string.IsNullOrEmpty(value as string))
            {
                return new ValidationResult(ErrorMessage ?? "This field is required for new users.", new[] { validationContext.MemberName! });
            }
        }

        return ValidationResult.Success;
    }
}
