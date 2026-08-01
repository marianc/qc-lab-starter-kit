using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class FormParam
{
    public long FormId { get; set; }

    public long TestId { get; set; }

    public bool IsCalculated { get; set; }

    public string? Formula { get; set; }

    public string? FormulaDependencies { get; set; }

    public string? CodeRelatedArrays { get; set; }

    public bool HasCondition { get; set; }

    public string? Condition { get; set; }

    public string? ConditionNote { get; set; }

    public bool IsRequired { get; set; }

    public decimal? DefaultValue { get; set; }

    public long NrOrd { get; set; }

    public long NrOrdCalc { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual Test Test { get; set; } = null!;
}
