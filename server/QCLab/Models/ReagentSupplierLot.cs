using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentSupplierLot
{
    public long ControlCodeId { get; set; }

    public string Name { get; set; } = null!;

    public string? CatalogNumber { get; set; }

    public string? Supplier { get; set; }

    public string ManufacturerLotNumber { get; set; } = null!;

    public string? CertificateOfAnalysisRef { get; set; }

    public virtual ReagentLot ControlCode { get; set; } = null!;
}
