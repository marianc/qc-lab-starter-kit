using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class TestEnum
{
    public long TestId { get; set; }

    public long Value { get; set; }

    public string Name { get; set; } = null!;

    public long NrOrd { get; set; }

    public bool IsObsolete { get; set; }

    public virtual Test Test { get; set; } = null!;
}
