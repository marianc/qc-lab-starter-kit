using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Line-item analytical test evaluations displayed on the Quality Certificate / Certificate of Analysis (COA). Contains evaluated test results, expanded uncertainty values, individual specification compliance flags (is_conforming_spec), guard-band compliance flags (is_conforming_uncertainty), and snapshots of specification limits (note_spec).
/// </summary>
public partial class CertificateTest
{
    /// <summary>
    /// Primary key and foreign key referencing public.certificates(id). The parent quality certificate.
    /// </summary>
    public long CertificateId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.reports(id). The source test report providing the data.
    /// </summary>
    public long ReportId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.measurements(id). The raw measurement session.
    /// </summary>
    public long MeasurementId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical test evaluated.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Determination index (0 for scalar, 0..N for replicated arrays).
    /// </summary>
    public int Idx { get; set; }

    /// <summary>
    /// Certified analytical test result value.
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Expanded measurement uncertainty U associated with the certified result.
    /// </summary>
    public decimal? UncertaintyValue { get; set; }

    /// <summary>
    /// Coverage factor k (typically 2.0) applied to the uncertainty estimate.
    /// </summary>
    public decimal? CoverageFactorK { get; set; }

    /// <summary>
    /// Boolean flag. Evaluated by executing the specification condition formula (spec_tests.condition) against the measured value. True if value meets specification limits; false otherwise.
    /// </summary>
    public bool IsConformingSpec { get; set; }

    /// <summary>
    /// Boolean flag. Evaluated by checking whether both [value - uncertainty_value] AND [value + uncertainty_value] satisfy the specification condition formula. Enforces ILAC-G8 guard-banding rules for ISO/IEC 17025 accredited reporting.
    /// </summary>
    public bool IsConformingUncertainty { get; set; }

    /// <summary>
    /// Historical snapshot text of the specification acceptance criteria in effect at the time of certification (maximum 25 characters, e.g., &apos;&gt;= 98.0%&apos;, &apos;Clear liquid&apos;). Preserves exact historical limits regardless of future spec revisions.
    /// </summary>
    public string NoteSpec { get; set; } = null!;

    /// <summary>
    /// Integer count of determinations or replicates performed to establish this result (defaults to 0).
    /// </summary>
    public int TestCount { get; set; }

    public virtual Certificate Certificate { get; set; } = null!;

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Report Report { get; set; } = null!;

    public virtual ReportTest ReportTest { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
