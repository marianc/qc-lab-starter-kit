using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Master inventory register of laboratory instruments, analytical balances, chromatography systems, and spectrophotometers. Tracks physical location, serial numbers, calibration schedules, and operational readiness under ISO/IEC 17025 and 21 CFR Part 211.
/// </summary>
public partial class Equipment
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the equipment asset.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique laboratory internal asset tag or barcode (2 to 20 characters, e.g., &apos;BAL-001&apos;, &apos;HPLC-UV-03&apos;). Used on sample worksheets and equipment selection dialogs.
    /// </summary>
    public string EquipmentCode { get; set; } = null!;

    /// <summary>
    /// Descriptive equipment title (2 to 100 characters, e.g., &apos;Analytical Balance XP205&apos;, &apos;UV-Vis Spectrophotometer Evolution 300&apos;).
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Name of the equipment manufacturer or OEM (maximum 100 characters, e.g., &apos;Mettler Toledo&apos;, &apos;Waters&apos;, &apos;Agilent&apos;).
    /// </summary>
    public string? Manufacturer { get; set; }

    /// <summary>
    /// Manufacturer model number or instrument family (maximum 100 characters, e.g., &apos;Alliance e2695&apos;, &apos;XS204&apos;).
    /// </summary>
    public string? Model { get; set; }

    /// <summary>
    /// Unique manufacturer serial number (maximum 100 characters). Enforces instrument hardware identity.
    /// </summary>
    public string SerialNumber { get; set; } = null!;

    /// <summary>
    /// Laboratory room, bench, or cleanroom zone where the instrument is installed (maximum 100 characters, e.g., &apos;QC Phys-Chem Room 204&apos;).
    /// </summary>
    public string? Location { get; set; }

    /// <summary>
    /// Foreign key referencing public.equipment_statuses(id). Operational state of the instrument. Automatically set to &apos;Active&apos; when a successful calibration is recorded in EquipmentsService.AddEquipmentCalibration.
    /// </summary>
    public long StatusId { get; set; }

    /// <summary>
    /// Number of days between required periodic recalibrations (integer, defaults to 365 days / 1 year).
    /// </summary>
    public int? CalibrationIntervalDays { get; set; }

    /// <summary>
    /// Calendar date when the instrument must next undergo calibration. Automatically updated from the expiration_date of the most recently recorded calibration certificate.
    /// </summary>
    public DateOnly? NextCalibrationDue { get; set; }

    /// <summary>
    /// Timestamp with time zone when the equipment asset was registered in the database. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual ICollection<EquipmentCalibration> EquipmentCalibrations { get; set; } = new List<EquipmentCalibration>();

    public virtual EquipmentStatus Status { get; set; } = null!;

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
