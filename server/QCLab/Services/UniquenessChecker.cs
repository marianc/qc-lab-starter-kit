using QCLab.Client.Validation;
using QCLab.Models;

namespace QCLab.Services;

public class UniquenessChecker : IUniquenessChecker
{
    private readonly QualityControlContext _context;

    public UniquenessChecker(QualityControlContext context)
    {
        _context = context;
    }

    public bool IsUnique(string entityName, string propertyName, object value, object? entityId)
    {
        if (entityName == "User")
        {
            long userId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) userId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) userId = parsedId;
            }
            
            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.Users.Any(u => u.Tag == strValue && u.Id != userId);
            }
            if (propertyName == "Code")
            {
                return !_context.Users.Any(u => u.Code == strValue && u.Id != userId);
            }
            if (propertyName == "Email")
            {
                return !_context.Users.Any(u => u.Email == strValue && u.Id != userId);
            }
        }
        else if (entityName == "Material")
        {
            long materialId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) materialId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) materialId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.Materials.Any(m => m.Name == strValue && m.Id != materialId);
            }
            if (propertyName == "Code")
            {
                return !_context.Materials.Any(m => m.Code == strValue && m.Id != materialId);
            }
        }
        else if (entityName == "Unit")
        {
            long unitId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) unitId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) unitId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                // SQLite string comparison is case-insensitive by default. 
                // We use EF.Functions.Collate or just regular comparison if DB configured correctly.
                // Assuming default SQLite behavior, we need case-sensitive check.
                return !_context.Units.AsEnumerable().Any(u => string.Equals(u.Name, strValue, StringComparison.Ordinal) && u.Id != unitId);
            }
        }
        else if (entityName == "Equipment")
        {
            long equipmentId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) equipmentId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) equipmentId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "EquipmentCode")
            {
                return !_context.Equipments.Any(e => e.EquipmentCode == strValue && e.Id != equipmentId);
            }
            if (propertyName == "SerialNumber")
            {
                return !_context.Equipments.Any(e => e.SerialNumber == strValue && e.Id != equipmentId);
            }
        }
        else if (entityName == "Norm")
        {
            long normId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) normId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) normId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.Norms.Any(n => n.Name == strValue && n.Id != normId);
            }
        }
        else if (entityName == "Category")
        {
            long categoryId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) categoryId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) categoryId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.Categories.Any(c => c.Name == strValue && c.Id != categoryId);
            }
            if (propertyName == "Code")
            {
                return !_context.Categories.Any(c => c.Code == strValue && c.Id != categoryId);
            }
        }
        else if (entityName == "Test")
        {
            long testId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) testId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) testId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.Tests.Any(t => t.Name == strValue && t.Id != testId);
            }
            if (propertyName == "Code")
            {
                return !_context.Tests.Any(t => t.Code == strValue && t.Id != testId);
            }
        }
        else if (entityName == "Sop")
        {
            long sopId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) sopId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) sopId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "DocCode")
            {
                return !_context.Sops.Any(s => s.DocCode == strValue && s.Id != sopId);
            }
        }
        else if (entityName == "ReagentSupplier")
        {
            long supplierId = 0;
            if (entityId != null)
            {
                if (entityId is long idInt) supplierId = idInt;
                else if (long.TryParse(entityId.ToString(), out long parsedId)) supplierId = parsedId;
            }

            string? strValue = value as string;
            if (string.IsNullOrEmpty(strValue)) return true;

            if (propertyName == "Name")
            {
                return !_context.ReagentSuppliers.Any(s => s.Name == strValue && s.Id != supplierId);
            }
        }

        return true;
    }
    public bool IsUniqueScoped(string entityName, string propertyName, object value, object? entityId, object? scopeId)
    {
        if (entityName == "TestEnum")
        {
            if (scopeId == null) return true;
           
            long testId = 0;
            if (scopeId is long sInt) testId = sInt;
            else if (long.TryParse(scopeId.ToString(), out long p)) testId = p;

            long? originalValue = null;
            if (entityId != null)
            {
                if (entityId is long eId) originalValue = eId;
                else if (long.TryParse(entityId.ToString(), out long pe)) originalValue = pe;
            }

            if (propertyName == "Value")
            {
                long enumValue = 0;
                if (value is long v) enumValue = v;
                else long.TryParse(value.ToString(), out enumValue);

                var query = _context.TestEnums.Where(e => e.TestId == testId && e.Value == enumValue);
                
                if (originalValue.HasValue)
                {
                    query = query.Where(e => e.Value != originalValue.Value);
                }

                return !query.Any();
            }

            if (propertyName == "Name")
            {
                string? strValue = value as string;
                if (string.IsNullOrEmpty(strValue)) return true;

                var query = _context.TestEnums.Where(e => e.TestId == testId && e.Name == strValue);
                
                if (originalValue.HasValue)
                {
                    query = query.Where(e => e.Value != originalValue.Value);
                }

                return !query.Any();
            }
        }
        else if (entityName == "ControlCode")
        {
            if (scopeId == null) return true;

            long materialId = 0;
            if (scopeId is long sInt) materialId = sInt;
            else if (long.TryParse(scopeId.ToString(), out long p)) materialId = p;

            long? entityIdInt = null;
            if (entityId != null)
            {
                if (entityId is long eId) entityIdInt = eId;
                else if (long.TryParse(entityId.ToString(), out long pe)) entityIdInt = pe;
            }

            if (propertyName == "Code")
            {
                string? strValue = value as string;
                if (string.IsNullOrEmpty(strValue)) return true;

                return !_context.ControlCodes.Any(c => c.MaterialId == materialId && c.Code == strValue && c.Id != entityIdInt);
            }
        }
        else if (entityName == "SopVersion")
        {
            if (scopeId == null) return true;

            long sopId = 0;
            if (scopeId is long sInt) sopId = sInt;
            else if (long.TryParse(scopeId.ToString(), out long p)) sopId = p;

            long? versionId = null;
            if (entityId != null)
            {
                if (entityId is long eId) versionId = eId;
                else if (long.TryParse(entityId.ToString(), out long pe)) versionId = pe;
            }

            if (propertyName == "VersionNumber")
            {
                string? strValue = value as string;
                if (string.IsNullOrEmpty(strValue)) return true;

                return !_context.SopVersions.Any(v => v.SopId == sopId && v.VersionNumber == strValue && v.Id != versionId);
            }
        }

        return true;
    }
}
