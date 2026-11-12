using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Historical calibration log and certificate registry for laboratory instruments. Adding or updating a calibration certificate in EquipmentCalibrationDialog.tsx automatically propagates the expiration_date to equipments.next_calibration_due and restores the instrument status to &apos;Active&apos;.
/// </summary>
public partial class EquipmentCalibration
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the calibration event.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.equipments(id). The laboratory instrument subjected to calibration.
    /// </summary>
    public long EquipmentId { get; set; }

    /// <summary>
    /// Date when the physical calibration procedure was performed.
    /// </summary>
    public DateOnly CalibrationDate { get; set; }

    /// <summary>
    /// Date when this calibration certificate expires. Automatically updates equipments.next_calibration_due.
    /// </summary>
    public DateOnly ExpirationDate { get; set; }

    /// <summary>
    /// Unique external or internal calibration certificate tracking number (maximum 100 characters, e.g., &apos;CAL-2026-09871&apos;).
    /// </summary>
    public string CertificateNumber { get; set; } = null!;

    /// <summary>
    /// Name of the accredited metrology calibration service provider or internal calibration technician (maximum 100 characters).
    /// </summary>
    public string CalibratedBy { get; set; } = null!;

    /// <summary>
    /// Foreign key referencing public.equipment_calibration_statuses(id) (1=&apos;Pass&apos;, 2=&apos;Fail&apos;, 3=&apos;Limited Use&apos;).
    /// </summary>
    public long StatusId { get; set; }

    /// <summary>
    /// Text details of traceable reference standards (e.g., NIST-traceable weights, calibrated quartz cuvettes) utilized during the calibration.
    /// </summary>
    public string? ReferenceStandardsUsed { get; set; }

    /// <summary>
    /// Expanded measurement uncertainty of the calibration method itself (NUMERIC), as stated on the calibration certificate.
    /// </summary>
    public decimal? ExpandedUncertainty { get; set; }

    /// <summary>
    /// Timestamp with time zone when the calibration record was logged into the system. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual Equipment Equipment { get; set; } = null!;

    public virtual EquipmentCalibrationStatus Status { get; set; } = null!;
}
