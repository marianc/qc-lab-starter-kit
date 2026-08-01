using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Category
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string Code { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime DateCreated { get; set; }

    public bool IsObsolete { get; set; }

    public DateTime? DateObsolete { get; set; }

    public string? CommentsObsolete { get; set; }

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
