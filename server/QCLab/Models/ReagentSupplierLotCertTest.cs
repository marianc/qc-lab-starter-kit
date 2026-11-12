using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Certified reference parameter values transcribed from manufacturer Certificates of Analysis (CoA) for Certified Reference Materials (CRMs). Enables strict metrological traceability under ISO 17034 and ISO/IEC 17025. When executing a worksheet with CRM-dependent parameters (tests.for_certified_reference = true), the analyst selects active values from this table via SelectCrmDialog.tsx.
/// </summary>
public partial class ReagentSupplierLotCertTest
{
    /// <summary>
    /// Primary key and foreign key referencing public.control_codes(id). Identifies the supplier CRM reagent lot.
    /// </summary>
    public long ControlCodeId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical property or analyte certified on the supplier CoA.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Certified reference numerical value stated on the manufacturer CoA (e.g., 99.98% purity, 0.1002 N titer).
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Stated expanded measurement uncertainty U from the manufacturer certificate (e.g., 0.05).
    /// </summary>
    public decimal? UncertaintyValue { get; set; }

    /// <summary>
    /// Coverage factor k stated on the certificate (typically 2.0 for approx. 95% confidence interval).
    /// </summary>
    public decimal? CoverageFactorK { get; set; }

    /// <summary>
    /// Formal metrological traceability text transcribed from the CoA (maximum 500 characters, e.g., &apos;Traceable to NIST SRM 84k&apos;).
    /// </summary>
    public string? TraceabilityStatement { get; set; }

    public virtual ReagentSupplierLot ControlCode { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
