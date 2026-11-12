using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Versioned document releases of Standard Operating Procedures (SOPs). Ensures compliance with document control guidelines by tracking active versus retired revisions and linking to external Electronic Document Management Systems (EDMS). Individual test measurements link to the exact sop_version_id in effect during execution.
/// </summary>
public partial class SopVersion
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the SOP version revision.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.sops(id). Identifies the parent SOP to which this revision belongs.
    /// </summary>
    public long SopId { get; set; }

    /// <summary>
    /// Revision string (maximum 20 characters, e.g., &apos;1.0&apos;, &apos;2.3&apos;, &apos;Rev C&apos;). Unique per parent SOP.
    /// </summary>
    public string VersionNumber { get; set; } = null!;

    /// <summary>
    /// External document management system identifier or hyperlink (maximum 100 characters) pointing to the controlled document PDF in the EDMS.
    /// </summary>
    public string? ExternalEdmsId { get; set; }

    /// <summary>
    /// Change control summary or revision history notes describing the updates introduced in this version.
    /// </summary>
    public string? Comments { get; set; }

    /// <summary>
    /// Boolean flag indicating whether this specific SOP version is currently active and authorized for analytical testing. Worksheet sessions query active SOP versions for logging test execution methods.
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// Timestamp with time zone when this SOP version was officially authorized and released into production. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateActivated { get; set; }

    public virtual Sop Sop { get; set; } = null!;

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();
}
