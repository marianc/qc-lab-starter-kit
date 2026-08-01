namespace QCLab.Client.Validation;

public interface IUniquenessChecker
{
    bool IsUnique(string entityName, string propertyName, object value, object? entityId);
    bool IsUniqueScoped(string entityName, string propertyName, object value, object? entityId, object? scopeId);
}
