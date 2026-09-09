using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentLotStatus
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<ReagentLot> ReagentLots { get; set; } = new List<ReagentLot>();
}
