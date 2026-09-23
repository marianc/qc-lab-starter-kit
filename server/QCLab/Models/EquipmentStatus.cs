using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class EquipmentStatus
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();
}
