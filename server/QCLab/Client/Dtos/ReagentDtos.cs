using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class ReagentDto
{
    public long Id { get; set; }

    [Unique("Material", ErrorMessage = "Reagent name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Unique("Material", ErrorMessage = "Reagent code is already in use.")]
    [StringLength(5, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 5 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
    public string? CasNumber { get; set; }
    public long? NormId { get; set; }
    public string? NormName { get; set; }
    public bool IsObsolete { get; set; }
    public DateTime DateCreated { get; set; }
    public DateTime? DateObsolete { get; set; }
    public string? CommentsObsolete { get; set; }
}

public class CreateReagentDto
{
    [Unique("Material", ErrorMessage = "Reagent name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Unique("Material", ErrorMessage = "Reagent code is already in use.")]
    [StringLength(5, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 5 characters.")]
    [RegularExpression("^[A-Z][A-Z0-9]*$", ErrorMessage = "Code must start with a letter and contain only uppercase alphanumeric characters.")]
    public required string Code { get; set; }

    public string? Description { get; set; }
    public string? CasNumber { get; set; }
    public long? NormId { get; set; }
    public bool IsObsolete { get; set; }
}

public class UpdateReagentDto : CreateReagentDto { }

public class ReagentLotStatusDto
{
    public long Id { get; set; }
    public required string Name { get; set; }
}

public class ReagentLotDto
{
    public long ControlCodeId { get; set; }
    public long MaterialId { get; set; }
    public required string ControlCode { get; set; }
    public bool IsProduced { get; set; }
    public long? ProducedByUserId { get; set; }
    public string? ProducedByUserTag { get; set; }
    public long StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public long? UnitId { get; set; }
    public string? UnitName { get; set; }
    public decimal Quantity { get; set; }
    public DateOnly ExpirationDate { get; set; }
    public DateTime DateCreated { get; set; }

    // Supplier Lot details (if !IsProduced)
    public string? SupplierLotName { get; set; }
    public string? CatalogNumber { get; set; }
    public string? Supplier { get; set; }
    public string? ManufacturerLotNumber { get; set; }
    public string? CertificateOfAnalysisRef { get; set; }

    // Production Lot details (if IsProduced)
    public List<long> IngredientControlCodeIds { get; set; } = new();
    public List<string> IngredientControlCodes { get; set; } = new();
}

public class CreateSupplierLotDto
{
    public long MaterialId { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Control code is required.")]
    public required string ControlCode { get; set; }
    public long StatusId { get; set; }
    public long? UnitId { get; set; }
    public decimal Quantity { get; set; }
    public DateOnly ExpirationDate { get; set; }

    [StringLength(100, MinimumLength = 1, ErrorMessage = "Name is required.")]
    public required string Name { get; set; }
    [StringLength(50)]
    public string? CatalogNumber { get; set; }
    [StringLength(100)]
    public string? Supplier { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Manufacturer lot number is required.")]
    public required string ManufacturerLotNumber { get; set; }
    [StringLength(255)]
    public string? CertificateOfAnalysisRef { get; set; }
}

public class UpdateSupplierLotDto
{
    public long StatusId { get; set; }
    public long? UnitId { get; set; }
    public decimal Quantity { get; set; }
    public DateOnly ExpirationDate { get; set; }

    [StringLength(100, MinimumLength = 1, ErrorMessage = "Name is required.")]
    public required string Name { get; set; }
    [StringLength(50)]
    public string? CatalogNumber { get; set; }
    [StringLength(100)]
    public string? Supplier { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Manufacturer lot number is required.")]
    public required string ManufacturerLotNumber { get; set; }
    [StringLength(255)]
    public string? CertificateOfAnalysisRef { get; set; }
}

public class CreateProductionLotDto
{
    public long MaterialId { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Control code is required.")]
    public required string ControlCode { get; set; }
    public long StatusId { get; set; }
    public long? UnitId { get; set; }
    public decimal Quantity { get; set; }
    public DateOnly ExpirationDate { get; set; }
    public long? ProducedByUserId { get; set; }
    public List<long> IngredientControlCodeIds { get; set; } = new();
}

public class UpdateProductionLotDto
{
    public long StatusId { get; set; }
    public long? UnitId { get; set; }
    public decimal Quantity { get; set; }
    public DateOnly ExpirationDate { get; set; }
    public long? ProducedByUserId { get; set; }
    public List<long> IngredientControlCodeIds { get; set; } = new();
}
