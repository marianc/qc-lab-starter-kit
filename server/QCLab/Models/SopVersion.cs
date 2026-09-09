using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class SopVersion
{
    public long Id { get; set; }

    public long SopId { get; set; }

    public string VersionNumber { get; set; } = null!;

    public string? ExternalEdmsId { get; set; }

    public string? Comments { get; set; }

    public bool IsActive { get; set; }

    public DateTime DateActivated { get; set; }

    public virtual Sop Sop { get; set; } = null!;

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();
}
