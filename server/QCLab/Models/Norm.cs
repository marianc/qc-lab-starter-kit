using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Norm
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime DateCreated { get; set; }

    public bool IsObsolete { get; set; }

    public DateTime? DateObsolete { get; set; }

    public string? CommentsObsolete { get; set; }

    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
