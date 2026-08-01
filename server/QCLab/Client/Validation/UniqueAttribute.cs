using System.ComponentModel.DataAnnotations;

namespace QCLab.Client.Validation;

[AttributeUsage(AttributeTargets.Property, AllowMultiple = false)]
public class UniqueAttribute : ValidationAttribute
{
    public string EntityName { get; }

    public UniqueAttribute(string entityName)
    {
        EntityName = entityName;
    }

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var service = validationContext.GetService(typeof(IUniquenessChecker)) as IUniquenessChecker;
        
        // If the service is not available (e.g., on the client), skip validation.
        // Uniqueness will be enforced by the server.
        if (service == null)
        {
            return ValidationResult.Success;
        }

        var idProperty = validationContext.ObjectType.GetProperty("Id");
        var entityId = idProperty?.GetValue(validationContext.ObjectInstance);

        if (!service.IsUnique(EntityName, validationContext.MemberName!, value!, entityId))
        {
            return new ValidationResult(ErrorMessage ?? $"{validationContext.MemberName} must be unique.", new[] { validationContext.MemberName! });
        }

        return ValidationResult.Success;
    }
}
