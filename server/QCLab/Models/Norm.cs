using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Compendial standards, pharmacopeias, or regulatory references (e.g., &apos;USP 43&apos;, &apos;Ph. Eur. 10&apos;, &apos;ISO/IEC 17025&apos;, &apos;ASTM D1298&apos;, &apos;Internal QC Standard&apos;). Provides governing normative authority for test methods, specifications, and standard operating procedures (SOPs).
/// </summary>
public partial class Norm
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the norm record.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique title or designation of the governing standard (3 to 50 characters). Validated for uniqueness in NormDialog.tsx.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Detailed description of the standard, governing body, publication edition, or scope.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Timestamp with time zone when the norm was registered.
    /// </summary>
    public DateTime DateCreated { get; set; }

    /// <summary>
    /// Soft-deletion flag. When true, prevents associating this norm with new materials, tests, or SOPs.
    /// </summary>
    public bool IsObsolete { get; set; }

    /// <summary>
    /// Timestamp with time zone when the norm was marked obsolete. Cleared to NULL if reactivated.
    /// </summary>
    public DateTime? DateObsolete { get; set; }

    /// <summary>
    /// Documented justification explaining why the norm is no longer valid or applicable. Cleared to NULL if reactivated.
    /// </summary>
    public string? CommentsObsolete { get; set; }

    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    public virtual ICollection<Sop> Sops { get; set; } = new List<Sop>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
