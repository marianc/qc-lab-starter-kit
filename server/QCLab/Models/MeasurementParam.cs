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

    public bool IsConformingCondition { get; set; }

    /// <summary>
    /// Foreign key pointing to the certified parameter value pulled from the active CRM inventory lot for tracking.
    /// </summary>
    public long? CertifiedReferenceCertificateId { get; set; }

    /// <summary>
    /// Foreign key pointing to the certified parameter value pulled from the active CRM inventory lot for tracking.
    /// </summary>
    public long? CertifiedReferenceControlCodeId { get; set; }

    public long? UserUpdatedId { get; set; }

    public DateTime? DateUpdated { get; set; }

    public long UserCreatedId { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual Certificate? CertifiedReferenceCertificate { get; set; }

    public virtual ReagentSupplierLot? CertifiedReferenceControlCode { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;

    public virtual User UserCreated { get; set; } = null!;

    public virtual User? UserUpdated { get; set; }
}
