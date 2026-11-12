using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Lookup catalog for operational status of analytical laboratory instruments: 1 = &apos;Active&apos; (calibrated, qualified, and authorized for routine testing), 2 = &apos;Inactive&apos; (standby or temporarily decommissioned), 3 = &apos;Calibration Due&apos; (calibration overdue, locked from testing), 4 = &apos;Out of Service&apos; (defective, undergoing repair, or failed calibration).
/// </summary>
public partial class EquipmentStatus
{
    /// <summary>
    /// Primary key. Unique identifier for the equipment operational status.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique status name (&apos;Active&apos;, &apos;Inactive&apos;, &apos;Calibration Due&apos;, &apos;Out of Service&apos;).
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();
}
