using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class SpecTest
{
    public long SpecId { get; set; }

    public long TestId { get; set; }

    public string Condition { get; set; } = null!;

    public string Note { get; set; } = null!;

    public bool UseUncertainty { get; set; }

    public int TestFrequency { get; set; }

    public virtual Spec Spec { get; set; } = null!;

    public virtual ICollection<SpecTestEval> SpecTestEvals { get; set; } = new List<SpecTestEval>();

    public virtual Test Test { get; set; } = null!;
}
