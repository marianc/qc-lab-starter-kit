using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class FormEval
{
    public long Id { get; set; }

    public long FormId { get; set; }

    public string? Description { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();
}
