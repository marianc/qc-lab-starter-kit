using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Standard Operating Procedures (SOPs) defining laboratory test methods and testing protocols. Optionally linked to a parent norm (norms). In TestDialog.tsx, choosing a norm filters the SOP dropdown to show only SOPs that reference that norm.
/// </summary>
public partial class Sop
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the SOP.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique official SOP document code (maximum 50 characters, e.g., &apos;SOP-QC-MET-0042&apos;). Validated for uniqueness via UniquenessChecker.
    /// </summary>
    public string DocCode { get; set; } = null!;

    /// <summary>
    /// Descriptive title of the standard operating procedure (up to 150 characters, e.g., &apos;Determination of Water Content by Karl Fischer Titration&apos;).
    /// </summary>
    public string Title { get; set; } = null!;

    /// <summary>
    /// Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial norm or pharmacopeia from which this SOP is derived.
    /// </summary>
    public long? NormId { get; set; }

    /// <summary>
    /// Numeric display and sequence ordering index (defaults to 0).
    /// </summary>
    public long NrOrd { get; set; }

    /// <summary>
    /// Timestamp with time zone when the SOP record was created. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<SopVersion> SopVersions { get; set; } = new List<SopVersion>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
