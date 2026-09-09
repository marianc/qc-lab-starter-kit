using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentLot
{
    public long ControlCodeId { get; set; }

    public bool IsProduced { get; set; }

    public long? ProducedByUserId { get; set; }

    public long StatusId { get; set; }

    public long? UnitId { get; set; }

    public decimal Quantity { get; set; }

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
