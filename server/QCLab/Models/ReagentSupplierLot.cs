using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Specialization table for commercially purchased reagent lots (reagent_lots where is_produced = false). Maintains manufacturer traceability, vendor catalog numbers, manufacturer batch numbers, and Certificate of Analysis (CoA) references. Locked into read-only mode once utilized in certified worksheets.
/// </summary>
public partial class ReagentSupplierLot
{
    /// <summary>
    /// Primary key and foreign key referencing public.control_codes(id) (and implicitly public.reagent_lots). Unique lot identifier.
    /// </summary>
    public long ControlCodeId { get; set; }

    /// <summary>
    /// Foreign key referencing public.reagent_suppliers(id). Identifies the vendor or manufacturer who supplied the batch. In SupplierLotDialog.tsx, user can either select an existing supplier or input a new one, which creates a new supplier record.
    /// </summary>
    public long SupplierId { get; set; }

    /// <summary>
    /// Vendor catalog or product article number (maximum 50 characters, e.g., &apos;1.00014.1000&apos;).
    /// </summary>
    public string? CatalogNumber { get; set; }

    /// <summary>
    /// Original manufacturer production lot number printed on the container label (maximum 50 characters).
    /// </summary>
    public string ManufacturerLotNumber { get; set; } = null!;

    /// <summary>
    /// Reference identifier, document number, or URL to the manufacturer&apos;s Certificate of Analysis (maximum 255 characters).
    /// </summary>
    public string? CertificateOfAnalysisRef { get; set; }

    /// <summary>
    /// Optional comments, container condition, or receiving notes (maximum 255 characters).
    /// </summary>
    public string? Comments { get; set; }

    /// <summary>
    /// Boolean lock flag (defaults to false). Automatically set to true when the lot is consumed in approved/submitted testing worksheets or quality certificates to guarantee immutable historical records.
    /// </summary>
    public bool IsReadonly { get; set; }

    /// <summary>
    /// Timestamp with time zone when the record was locked against modifications.
    /// </summary>
    public DateTime? DateReadonly { get; set; }

    public virtual ReagentLot ControlCode { get; set; } = null!;

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ReagentSupplierLotCertTest? ReagentSupplierLotCertTest { get; set; }

    public virtual ReagentSupplier Supplier { get; set; } = null!;
}
