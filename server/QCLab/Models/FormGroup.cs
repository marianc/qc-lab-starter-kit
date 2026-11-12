using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Logical family or category of dynamic analytical worksheet forms (e.g., &apos;Dissolution Testing Forms&apos;, &apos;Heavy Metals Assay Forms&apos;, &apos;Loss on Drying Forms&apos;). Controls overarching validation status across form versions.
/// </summary>
public partial class FormGroup
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the form group.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the form family (3 to 50 characters). Validated for uniqueness via FormGroupDialog.tsx.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Optional extended description of the testing domain and analytical methodologies handled by this form group.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Boolean status flag. Automatically updated to true when any form version within this group achieves validation approval (FormsService.ValidateForm). Signals that test definitions associated with this group are locked from structurally breaking changes.
    /// </summary>
    public bool IsFormValidated { get; set; }

    /// <summary>
    /// Numeric display order index (defaults to 0) controlling grouping sequence in client menus.
    /// </summary>
    public long NrOrd { get; set; }

    public virtual ICollection<Form> Forms { get; set; } = new List<Form>();
}
