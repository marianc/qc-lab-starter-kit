using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ValueType
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
