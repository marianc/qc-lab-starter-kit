using System.ComponentModel.DataAnnotations;
using QCLab.Client.Validation;

namespace QCLab.Client.Dtos;

public class EquipmentDto
{
    public long Id { get; set; }

    [Unique("Equipment", ErrorMessage = "Equipment code is already in use.")]
    [StringLength(20, MinimumLength = 2, ErrorMessage = "Equipment code must be between 2 and 20 characters.")]
    public required string EquipmentCode { get; set; }

    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be between 2 and 100 characters.")]
    public required string Name { get; set; }

    [StringLength(100)]
    public string? Manufacturer { get; set; }

    [StringLength(100)]
    public string? Model { get; set; }

    [StringLength(50, MinimumLength = 1, ErrorMessage = "Serial number is required.")]
    public required string SerialNumber { get; set; }

    [StringLength(100)]
    public string? Location { get; set; }

    [StringLength(50)]
    public required string Status { get; set; }

    public int? CalibrationIntervalDays { get; set; }

    public DateOnly? NextCalibrationDue { get; set; }

    public DateTime DateCreated { get; set; }
}

public class CreateEquipmentDto
{
    [Unique("Equipment", ErrorMessage = "Equipment code is already in use.")]
    [StringLength(20, MinimumLength = 2, ErrorMessage = "Equipment code must be between 2 and 20 characters.")]
    public required string EquipmentCode { get; set; }

    [StringLength(100, MinimumLength = 2, ErrorMessage = "Name must be between 2 and 100 characters.")]
    public required string Name { get; set; }

    [StringLength(100)]
    public string? Manufacturer { get; set; }

    [StringLength(100)]
    public string? Model { get; set; }

    [StringLength(50, MinimumLength = 1, ErrorMessage = "Serial number is required.")]
    public required string SerialNumber { get; set; }

    [StringLength(100)]
    public string? Location { get; set; }

    [StringLength(50)]
    public required string Status { get; set; }

    public int? CalibrationIntervalDays { get; set; }
}

public class UpdateEquipmentDto : CreateEquipmentDto { }

public class EquipmentCalibrationDto
{
    public long Id { get; set; }
    public long EquipmentId { get; set; }
    public DateOnly CalibrationDate { get; set; }
    public DateOnly ExpirationDate { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Certificate number is required.")]
    public required string CertificateNumber { get; set; }
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Calibrated by is required.")]
    public required string CalibratedBy { get; set; }
    [StringLength(50)]
    public required string ResultStatus { get; set; }
    public string? ReferenceStandardsUsed { get; set; }
    public decimal? ExpandedUncertainty { get; set; }
    public DateTime DateCreated { get; set; }
}

public class CreateEquipmentCalibrationDto
{
    public DateOnly CalibrationDate { get; set; }
    public DateOnly ExpirationDate { get; set; }
    [StringLength(50, MinimumLength = 1, ErrorMessage = "Certificate number is required.")]
    public required string CertificateNumber { get; set; }
    [StringLength(100, MinimumLength = 1, ErrorMessage = "Calibrated by is required.")]
    public required string CalibratedBy { get; set; }
    [StringLength(50)]
    public required string ResultStatus { get; set; }
    public string? ReferenceStandardsUsed { get; set; }
    public decimal? ExpandedUncertainty { get; set; }
}
