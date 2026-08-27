using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class TestEnumDto
{
    public long TestId { get; set; }

    [Required]
    [ScopedUnique("TestEnum", "TestId", IdentityPropertyName = "OriginalValue", ErrorMessage = "Value must be unique for this test.")]
    public long Value { get; set; }

    [Required]
    [StringLength(50, ErrorMessage = "Name must be maximum 50 characters.")]
    [ScopedUnique("TestEnum", "TestId", IdentityPropertyName = "OriginalValue", ErrorMessage = "Name must be unique for this test.")]
    public required string Name { get; set; }

    public long NrOrd { get; set; }

    public long? OriginalValue { get; set; }
}

public class TestDto
{
    public long Id { get; set; }

    [Required(ErrorMessage = "Name is required.")]
    [Unique("Test", ErrorMessage = "Test name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    [Required(ErrorMessage = "Code is required.")]
    [Unique("Test", ErrorMessage = "Test code is already in use.")]
    [StringLength(50, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 50 characters.")]
    [RegularExpression(@"^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$", ErrorMessage = "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores.")]
    public required string Code { get; set; }

    public string? Description { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Value Type is required.")]
    public long TypeId { get; set; }

    public string TypeName { get; set; } = string.Empty;
    public long? UnitId { get; set; }
    public string? UnitName { get; set; }
    public long? NormId { get; set; }

    [StringLength(50, ErrorMessage = "Norm Ref must be maximum 50 characters.")]
    public string? NormRef { get; set; }

    public bool IsParam { get; set; }
    public bool IsArray { get; set; }
    public bool ForCertification { get; set; }
    public bool IsFormValidated { get; set; }
    public long NrOrd { get; set; }
    public bool IsObsolete { get; set; }
    public DateTime? DateCreated { get; set; }
    public DateTime? DateObsolete { get; set; }
    public string? CommentsObsolete { get; set; }
    public List<TestEnumDto>? Enums { get; set; }

    [EnumListValidator]
    public string? EnumListString { get; set; }
}

public class CreateTestEnumDto
{
    public long Value { get; set; }
    public required string Name { get; set; }
    public long NrOrd { get; set; }
}

public class CreateTestDto
{
    [Required(ErrorMessage = "Name is required.")]
    [Unique("Test", ErrorMessage = "Test name is already in use.")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "Name must be between 3 and 50 characters.")]
    public required string Name { get; set; }

    public string? Description { get; set; }

    [Required(ErrorMessage = "Code is required.")]
    [Unique("Test", ErrorMessage = "Test code is already in use.")]
    [StringLength(50, MinimumLength = 2, ErrorMessage = "Code must be between 2 and 50 characters.")]
    [RegularExpression(@"^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$", ErrorMessage = "Code must start with a letter, end with an alphanumeric character, contain only alphanumeric characters and underscores, and cannot have consecutive underscores.")]
    public required string Code { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Value Type is required.")]
    public long TypeId { get; set; }

    public bool IsParam { get; set; }
    public long? UnitId { get; set; }
    public long? NormId { get; set; }

    [StringLength(50, ErrorMessage = "Norm Ref must be maximum 50 characters.")]
    public string? NormRef { get; set; }

    public long NrOrd { get; set; }
    public bool IsObsolete { get; set; }
    public bool IsArray { get; set; }
    public bool ForCertification { get; set; }
    public List<CreateTestEnumDto>? Enums { get; set; }
}

public class UpdateTestDto : CreateTestDto { }

public class ReorderTestDto
{
    public long Id { get; set; }
    public long NrOrd { get; set; }
}

public class ReorderTestEnumDto
{
    public long Value { get; set; }
    public long NrOrd { get; set; }
}

public class UpdateTestEnumDto
{
    public long Value { get; set; }
    public required string Name { get; set; }
    public long NrOrd { get; set; }
}

public class TestEquipmentDto
{
    public long Id { get; set; }
    public required string EquipmentCode { get; set; }
    public required string Name { get; set; }
    public string? SerialNumber { get; set; }
    public string? Status { get; set; }
}

public class UpdateTestEquipmentsDto
{
    public List<long> EquipmentIds { get; set; } = new();
}

