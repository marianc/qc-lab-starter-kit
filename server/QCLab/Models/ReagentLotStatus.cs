using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Lifecycle status lookup table for physical laboratory reagent lots: 1 = &apos;Quarantined&apos; (pending incoming inspection or CoA verification), 2 = &apos;Active&apos; (approved for use in testing and production), 3 = &apos;Expired&apos; (past manufacturer expiration date, locked from usage), 4 = &apos;Depleted&apos; (inventory exhausted). Only lots in &apos;Active&apos; status can be consumed in measurement worksheets or used as ingredients in lab preparations.
/// </summary>
public partial class ReagentLotStatus
{
    /// <summary>
    /// Primary key. Numeric identifier corresponding to the reagent lot status.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the lot status (&apos;Quarantined&apos;, &apos;Active&apos;, &apos;Expired&apos;, &apos;Depleted&apos;).
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<ReagentLot> ReagentLots { get; set; } = new List<ReagentLot>();
}
