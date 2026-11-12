using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Core inventory table tracking physical containers and batches of chemical reagents, volumetric solutions, and standards in the laboratory. Each lot is identified by a control_code_id. Differentiates purchased vendor lots from in-house prepared solutions (is_produced). Enforces expiration date controls and stock balances.
/// </summary>
public partial class ReagentLot
{
    /// <summary>
    /// Primary key and foreign key referencing public.control_codes(id). Serves as the unique tracking lot identifier for this physical batch.
    /// </summary>
    public long ControlCodeId { get; set; }

    /// <summary>
    /// Boolean flag distinguishing in-house prepared reagents (true) from commercially purchased supplier lots (false). When true, produced_by_user_id and ingredient relationships in reagent_production_lots are enabled.
    /// </summary>
    public bool IsProduced { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The laboratory analyst who formulated or prepared the reagent solution. Populated only when is_produced is true.
    /// </summary>
    public long? ProducedByUserId { get; set; }

    /// <summary>
    /// Foreign key referencing public.reagent_lot_statuses(id) (defaults to 1 = &apos;Quarantined&apos;). Only lots in status 2 (&apos;Active&apos;) can be selected as worksheet consumables or production ingredients.
    /// </summary>
    public long StatusId { get; set; }

    /// <summary>
    /// Numeric stock quantity remaining in inventory (e.g., 500.0). Enforced to be non-negative on the client and server.
    /// </summary>
    public decimal Quantity { get; set; }

    /// <summary>
    /// Foreign key referencing public.units(id) (nullable). Specifies the unit of measurement for stock inventory (e.g., &apos;mL&apos;, &apos;g&apos;, &apos;L&apos;).
    /// </summary>
    public long? UnitId { get; set; }

    /// <summary>
    /// Calendar date when the reagent lot expires. The system blocks using expired lots in analytical testing.
    /// </summary>
    public DateOnly ExpirationDate { get; set; }

    public virtual ControlCode ControlCode { get; set; } = null!;

    public virtual User? ProducedByUser { get; set; }

    public virtual ReagentSupplierLot? ReagentSupplierLot { get; set; }

    public virtual ReagentLotStatus Status { get; set; } = null!;

    public virtual Unit? Unit { get; set; }

    public virtual ICollection<ReagentLot> ControlCodes { get; set; } = new List<ReagentLot>();

    public virtual ICollection<ReagentLot> IngredientControlCodes { get; set; } = new List<ReagentLot>();

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();
}
