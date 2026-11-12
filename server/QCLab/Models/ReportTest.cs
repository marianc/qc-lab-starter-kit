using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Analytical test results included in a formal testing report. Encapsulates measured values alongside calculated expanded measurement uncertainties (U) and coverage factors (k) in compliance with ISO/IEC 17025.
/// </summary>
public partial class ReportTest
{
    /// <summary>
    /// Primary key and foreign key referencing public.reports(id). The parent testing report.
    /// </summary>
    public long ReportId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.measurements(id). The source worksheet from which the measurement was obtained.
    /// </summary>
    public long MeasurementId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical test evaluated.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Determination replicate index (0 for scalar tests, 0..N for replicated arrays).
    /// </summary>
    public int Idx { get; set; }

    /// <summary>
    /// Reported test value (numerical measurement or enum key).
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Calculated expanded measurement uncertainty U = (value * relative_uncertainty_pct / 100), as established in test definitions. Defines the boundary of the measurement result at approximately 95% confidence.
    /// </summary>
    public decimal? UncertaintyValue { get; set; }

    /// <summary>
    /// Coverage factor k (typically 2.0) applied during uncertainty calculation.
    /// </summary>
    public decimal? CoverageFactorK { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Report Report { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
