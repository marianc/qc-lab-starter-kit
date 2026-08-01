using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReceptionType
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
