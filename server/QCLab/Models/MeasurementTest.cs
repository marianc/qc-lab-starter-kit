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

    public long? UserUpdatedId { get; set; }

    public DateTime? DateUpdated { get; set; }

    public long UserCreatedId { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;

    public virtual User UserCreated { get; set; } = null!;

    public virtual User? UserUpdated { get; set; }
}
