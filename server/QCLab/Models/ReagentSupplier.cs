using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentSupplier
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<ReagentSupplierLot> ReagentSupplierLots { get; set; } = new List<ReagentSupplierLot>();
}
