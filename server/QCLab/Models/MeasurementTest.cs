using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Final measured test results recorded during a worksheet session. Supports both scalar results (idx = 0) and multi-replicate array results (idx = 0..N). Serves as the raw data source for testing reports (report_tests) and quality certificates (certificate_tests).
/// </summary>
public partial class MeasurementTest
{
    /// <summary>
    /// Primary key and foreign key referencing public.measurements(id). The parent worksheet execution session.
    /// </summary>
    public long MeasurementId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical test whose result was determined.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Numeric replicate index (0 for scalar tests, 0..N for replicated array determinations).
    /// </summary>
    public int Idx { get; set; }

    /// <summary>
    /// The measured numerical result (or encoded enum key from test_enums). Captured via MeasurementTestDialog.tsx or auto-calculated from form parameters.
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Short analyst footnote or qualitative observation (maximum 20 characters, e.g., &apos;Re-injected&apos;, &apos;Outlier rejected&apos;).
    /// </summary>
    public string? Note { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who last updated this test value.
    /// </summary>
    public long? UserUpdatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when this test value was last updated.
    /// </summary>
    public DateTime? DateUpdated { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id). The analyst who recorded the initial measurement.
    /// </summary>
    public long UserCreatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the measurement was originally logged. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;

    public virtual User UserCreated { get; set; } = null!;

    public virtual User? UserUpdated { get; set; }
}
