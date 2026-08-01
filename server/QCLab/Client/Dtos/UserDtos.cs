using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class CreateUserDto
{
    [Unique("User", ErrorMessage = "Name is already in use.")]
    [StringLength(12, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 12 characters.")]
    [RegularExpression("^[a-z][a-z0-9_]*[a-z0-9]$", ErrorMessage = "Name must start with a letter, end with an alphanumeric character, contain only lowercase alphanumeric characters or underscores.")]
    public required string Tag { get; set; }

    [Unique("User", ErrorMessage = "Code is already in use.")]
    [StringLength(3, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 3 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public string? Code { get; set; }

    [Unique("User", ErrorMessage = "Email is already in use.")]
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Invalid email address.")]
    public required string Email { get; set; }

    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public bool IsAdmin { get; set; }
    public bool IsLabPers { get; set; }
    public bool IsQcPers { get; set; }

    [Required(ErrorMessage = "Password is required.")]
    [PasswordValidation]
    public required string Password { get; set; }
}

public class UpdateUserDto
{
    [Unique("User", ErrorMessage = "Tag name is already in use.")]
    [StringLength(12, MinimumLength = 3, ErrorMessage = "Tag name must be between 3 and 12 characters.")]
    [RegularExpression("^[a-z][a-z0-9_]*[a-z0-9]$", ErrorMessage = "Tag name must start with a letter, end with an alphanumeric character, contain only lowercase alphanumeric characters or underscores.")]
    public required string Tag { get; set; }

    [Unique("User", ErrorMessage = "Code is already in use.")]
    [StringLength(3, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 3 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public string? Code { get; set; }

    [Unique("User", ErrorMessage = "Email is already in use.")]
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Invalid email address.")]
    public required string Email { get; set; }

    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public bool IsAdmin { get; set; }
    public bool IsLabPers { get; set; }
    public bool IsQcPers { get; set; }
    public bool MustChangePassword { get; set; }
}

public class ToggleObsoleteDto
{
    public bool IsObsolete { get; set; }
    public string? Comments { get; set; }
}

public class ResetPasswordDto
{
    public required string NewPassword { get; set; }
    public required string ConfirmPassword { get; set; }
}
