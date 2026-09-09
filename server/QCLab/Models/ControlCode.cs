using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ControlCode
{
    public long Id { get; set; }

    public long MaterialId { get; set; }

    public string Code { get; set; } = null!;

    public bool IsReceptionReceived { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual ICollection<Certificate> Certificates { get; set; } = new List<Certificate>();

    public virtual Material Material { get; set; } = null!;

    public virtual ReagentLot? ReagentLot { get; set; }

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
