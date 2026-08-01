using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class MeasurementTest
{
    public long MeasurementId { get; set; }

    public long TestId { get; set; }

    public int Idx { get; set; }

    public decimal Value { get; set; }

    public string? Note { get; set; }

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
