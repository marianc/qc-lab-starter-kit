using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class EquipmentCalibration
{
    public long Id { get; set; }

    public long EquipmentId { get; set; }

    public DateOnly CalibrationDate { get; set; }

    public DateOnly ExpirationDate { get; set; }

    public string CertificateNumber { get; set; } = null!;

    public string CalibratedBy { get; set; } = null!;

    public long StatusId { get; set; }

    public string? ReferenceStandardsUsed { get; set; }

    public decimal? ExpandedUncertainty { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual Equipment Equipment { get; set; } = null!;

    public virtual EquipmentCalibrationStatus Status { get; set; } = null!;
}
