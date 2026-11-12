using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Central batch/lot identification and inventory tracking table. Every physical batch of manufactured product, raw material delivery, purchased reagent lot, or in-house prepared reagent is assigned a unique control code linked to its material. Serves as the primary traceability anchor across sample receptions, testing worksheets, quality certificates, and reagent genealogy.
/// </summary>
public partial class ControlCode
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the control code record.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.materials(id). The specific material, chemical, or product to which this batch/lot belongs.
    /// </summary>
    public long MaterialId { get; set; }

    /// <summary>
    /// Alphanumeric batch/control code string (up to 50 characters). Unique per material. Must contain no whitespace (enforced by regex /^\S*$/). In sample reception dialogs (CertificationDialog, VerificationDialog), users can select an existing control code or enter a new one, which is verified for uniqueness against the selected material via UniquenessChecker.
    /// </summary>
    public string Code { get; set; } = null!;

    /// <summary>
    /// Boolean status flag. Automatically updated from false to true when any sample reception referencing this control code is accepted into the laboratory (ReceptionsService.ReceiveReception). Signals that physical samples of this batch have been received in the lab.
    /// </summary>
    public bool IsReceptionReceived { get; set; }

    /// <summary>
    /// Timestamp with time zone when the control code was generated. Defaults to clock_timestamp().
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual ICollection<Certificate> Certificates { get; set; } = new List<Certificate>();

    public virtual Material Material { get; set; } = null!;

    public virtual ReagentLot? ReagentLot { get; set; }

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
