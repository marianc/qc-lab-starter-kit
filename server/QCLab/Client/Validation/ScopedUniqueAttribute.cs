using System.ComponentModel.DataAnnotations;

namespace QCLab.Client.Validation;

[AttributeUsage(AttributeTargets.Property, AllowMultiple = false)]
public class ScopedUniqueAttribute : ValidationAttribute
{
    public string EntityName { get; }
    public string ScopePropertyName { get; }
    public string IdentityPropertyName { get; set; } = "Id";

    public ScopedUniqueAttribute(string entityName, string scopePropertyName)
    {
        EntityName = entityName;
        ScopePropertyName = scopePropertyName;
    }

    protected override ValidationResult? IsValid(object? value, ValidationContext validationContext)
    {
        var service = validationContext.GetService(typeof(IUniquenessChecker)) as IUniquenessChecker;
        
        if (service == null)
        {
            return ValidationResult.Success;
        }

        var scopeProperty = validationContext.ObjectType.GetProperty(ScopePropertyName);
        var scopeValue = scopeProperty?.GetValue(validationContext.ObjectInstance);

        var idProperty = validationContext.ObjectType.GetProperty(IdentityPropertyName);
        var entityId = idProperty?.GetValue(validationContext.ObjectInstance);

        if (!service.IsUniqueScoped(EntityName, validationContext.MemberName!, value!, entityId, scopeValue))
        {
            return new ValidationResult(ErrorMessage ?? $"{validationContext.MemberName} must be unique within {ScopePropertyName}.", new[] { validationContext.MemberName! });
        }

        return ValidationResult.Success;
    }
}
