using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class FormConditionEval
{
    public long Id { get; set; }

    public long FormId { get; set; }

    public long TestId { get; set; }

    public decimal Value { get; set; }

    public decimal? Result { get; set; }

    public decimal ExpectedResult { get; set; }

    public bool IsMatch { get; set; }

    public string? Note { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
