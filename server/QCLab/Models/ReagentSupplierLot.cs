using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReagentSupplierLot
{
    public long ControlCodeId { get; set; }

    public long SupplierId { get; set; }

    public string? CatalogNumber { get; set; }

    public string ManufacturerLotNumber { get; set; } = null!;

    public string? CertificateOfAnalysisRef { get; set; }

    public string? Comments { get; set; }

    public bool IsReadonly { get; set; }

    public DateTime? DateReadonly { get; set; }

    public virtual ReagentLot ControlCode { get; set; } = null!;

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ReagentSupplierLotCertTest? ReagentSupplierLotCertTest { get; set; }

    public virtual ReagentSupplier Supplier { get; set; } = null!;
}
