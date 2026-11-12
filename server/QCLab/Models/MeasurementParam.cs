using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Intermediate calculation variables and raw parameter inputs captured during dynamic form worksheet execution. Maintains parameter-level acceptance status (is_conforming_condition) and metrological links to Certified Reference Materials (CRMs).
/// </summary>
public partial class MeasurementParam
{
    /// <summary>
    /// Primary key and foreign key referencing public.measurements(id). The parent worksheet session.
    /// </summary>
    public long MeasurementId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.forms(id). The active form template.
    /// </summary>
    public long FormId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The specific parameter test definition.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Array determination index (0 for scalar parameters, 0..N for array inputs).
    /// </summary>
    public int Idx { get; set; }

    /// <summary>
    /// Input raw measurement value or formula-calculated intermediate result.
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the parameter satisfies the conditional acceptance rule defined in form_params.condition.
    /// </summary>
    public bool IsConformingCondition { get; set; }

    /// <summary>
    /// Foreign key referencing public.certificates(id) (nullable). Populated when this parameter value is calibrated against or sourced from an internal Quality Certificate for a certified reference batch via SelectCrmDialog.tsx.
    /// </summary>
    public long? CertifiedReferenceCertificateId { get; set; }

    /// <summary>
    /// Foreign key referencing public.control_codes(id) (nullable). Populated when this parameter value is sourced from a supplier CRM reagent lot Certificate of Analysis (reagent_supplier_lot_cert_tests) via SelectCrmDialog.tsx.
    /// </summary>
    public long? CertifiedReferenceControlCodeId { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who last edited this parameter value.
    /// </summary>
    public long? UserUpdatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone of the most recent parameter edit.
    /// </summary>
    public DateTime? DateUpdated { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id). The user who originally recorded the parameter.
    /// </summary>
    public long UserCreatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the parameter was created. Defaults to clock_timestamp().
    /// </summary>
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
