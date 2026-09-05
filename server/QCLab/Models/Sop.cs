using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Sop
{
    public long Id { get; set; }

    public string DocCode { get; set; } = null!;

    public string Title { get; set; } = null!;

    public long? NormId { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<SopVersion> SopVersions { get; set; } = new List<SopVersion>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
