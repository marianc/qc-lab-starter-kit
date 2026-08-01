using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Unit
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
