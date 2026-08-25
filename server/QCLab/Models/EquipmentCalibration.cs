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

    public string ResultStatus { get; set; } = null!;

    public string? ReferenceStandardsUsed { get; set; }

    public decimal? ExpandedUncertainty { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual Equipment Equipment { get; set; } = null!;
}
