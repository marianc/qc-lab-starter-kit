using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentSupplierLotCertTest
{
    public long ControlCodeId { get; set; }

    public long TestId { get; set; }

    public decimal Value { get; set; }

    public decimal? UncertaintyValue { get; set; }

    public decimal? CoverageFactorK { get; set; }

    public string? TraceabilityStatement { get; set; }

    public virtual ReagentSupplierLot ControlCode { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
