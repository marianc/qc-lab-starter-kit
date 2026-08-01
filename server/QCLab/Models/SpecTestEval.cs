using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class SpecTestEval
{
    public long Id { get; set; }

    public long SpecId { get; set; }

    public long TestId { get; set; }

    public decimal? Value { get; set; }

    public decimal? Result { get; set; }

    public decimal ExpectedResult { get; set; }

    public bool IsMatch { get; set; }

    public string? Note { get; set; }

    public virtual Spec Spec { get; set; } = null!;

    public virtual SpecTest SpecTest { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
