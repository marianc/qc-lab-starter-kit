using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class FormEvalParam
{
    public long EvalId { get; set; }

    public long FormId { get; set; }

    public long TestId { get; set; }

    public int Idx { get; set; }

    public decimal? Value { get; set; }

    public decimal? ExpectedValue { get; set; }

    public bool IsMatch { get; set; }

    public virtual FormEval Eval { get; set; } = null!;

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
