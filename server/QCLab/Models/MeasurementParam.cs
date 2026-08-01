using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class MeasurementParam
{
    public long MeasurementId { get; set; }

    public long FormId { get; set; }

    public long TestId { get; set; }

    public int Idx { get; set; }

    public decimal Value { get; set; }

    public decimal? ConditionValue { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
