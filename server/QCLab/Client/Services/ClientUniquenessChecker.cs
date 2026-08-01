using QCLab.Client.Validation;

namespace QCLab.Client.Services;

public class ClientUniquenessChecker : IUniquenessChecker
{
    private readonly Dictionary<string, List<string>> _scopedCache = new(StringComparer.OrdinalIgnoreCase);

    public void UpdateScopedCache(string key, List<string> values)
    {
        _scopedCache[key] = values.Where(v => v != null).Select(v => v.Trim()).ToList();
    }

    public bool IsUnique(string entityName, string propertyName, object value, object? entityId)
    {
        return true;
    }

    public bool IsUniqueScoped(string entityName, string propertyName, object value, object? entityId, object? scopeId)
    {
        if (value == null) return true;
        string? valStr = value.ToString()?.Trim();
        if (string.IsNullOrEmpty(valStr)) return true;

        if (entityName == "ControlCode" && propertyName == "Code" && scopeId != null)
        {
            string key = $"ControlCode_Code_{scopeId}";
            if (_scopedCache.TryGetValue(key, out var codes))
            {
                return !codes.Any(c => string.Equals(c, valStr, StringComparison.OrdinalIgnoreCase));
            }
        }
        return true;
    }
}
