using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Master classification table grouping materials and products into logical families (e.g., &apos;Finished Products&apos;, &apos;Active Pharmaceutical Ingredients&apos;, &apos;Excipients&apos;, &apos;Solvents&apos;). Used for organizing catalog items and driving ad-hoc Category Verification sample receptions.
/// </summary>
public partial class Category
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the category.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the material category (3 to 50 characters). Validated for uniqueness on blur in CategoryDialog.tsx.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Unique 2 to 5 character uppercase alphanumeric classification code (regex /^[A-Z][A-Z0-9]*$/). Validated for uniqueness on the client and server.
    /// </summary>
    public string Code { get; set; } = null!;

    /// <summary>
    /// Optional extended description of the category scope and materials covered.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Timestamp with time zone when the category was established.
    /// </summary>
    public DateTime DateCreated { get; set; }

    /// <summary>
    /// Soft-deletion flag. When true, prevents the category from being selected in new material definitions or category verification receptions while preserving historical records.
    /// </summary>
    public bool IsObsolete { get; set; }

    /// <summary>
    /// Timestamp with time zone when the category was retired. Cleared to NULL if reactivated.
    /// </summary>
    public DateTime? DateObsolete { get; set; }

    /// <summary>
    /// Documented reason recorded when retiring the category. Cleared to NULL if reactivated.
    /// </summary>
    public string? CommentsObsolete { get; set; }

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
