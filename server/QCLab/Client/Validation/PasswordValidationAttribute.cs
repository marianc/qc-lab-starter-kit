using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace QCLab.Client.Validation;

public class PasswordValidationAttribute : ValidationAttribute
{
    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var password = value as string;

        // Allow null or empty (use [Required] if mandatory)
        if (string.IsNullOrEmpty(password))
        {
            return ValidationResult.Success;
        }

        if (password.Length < 8)
        {
            return new ValidationResult("Password must be at least 8 characters long.", new[] { validationContext.MemberName! });
        }
        if (!Regex.IsMatch(password, "[A-Z]"))
        {
            return new ValidationResult("Password must contain at least one uppercase letter.", new[] { validationContext.MemberName! });
        }
        if (!Regex.IsMatch(password, "[a-z]"))
        {
            return new ValidationResult("Password must contain at least one lowercase letter.", new[] { validationContext.MemberName! });
        }
        if (!Regex.IsMatch(password, "[0-9]"))
        {
            return new ValidationResult("Password must contain at least one number.", new[] { validationContext.MemberName! });
        }
        if (!Regex.IsMatch(password, "[^A-Za-z0-9]"))
        {
            return new ValidationResult("Password must contain at least one special character.", new[] { validationContext.MemberName! });
        }

        return ValidationResult.Success;
    }
}
