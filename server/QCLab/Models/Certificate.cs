using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Official Quality Certificates / Certificates of Analysis (COA) issued for a manufactured batch or raw material lot (control_code_id). Evaluates laboratory test results against the active specification (spec_id). Computes both direct specification conformance and uncertainty guard-band conformance (ISO/IEC 17025 / ILAC-G8). Enforces 21 CFR Part 11 digital signatures on approval.
/// </summary>
public partial class Certificate
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the quality certificate.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.control_codes(id). The batch or inventory lot covered by this certificate.
    /// </summary>
    public long ControlCodeId { get; set; }

    /// <summary>
    /// Foreign key referencing public.specs(id). The active specification used to evaluate batch conformance.
    /// </summary>
    public long SpecId { get; set; }

    /// <summary>
    /// Boolean conformance flag. True indicates that ALL required tests meet specification limits and no mandatory specification tests are missing. Calculated automatically by CertificatesService.CalculateAndSaveCertificateTests.
    /// </summary>
    public bool IsConformingSpec { get; set; }

    /// <summary>
    /// Boolean guard-band conformance flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. True indicates that both the lower bound [value - U] and upper bound [value + U] fall within the specification acceptance range for all tests.
    /// </summary>
    public bool IsConformingUncertainty { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the Quality Certificate has been formally approved and released with a 21 CFR Part 11 electronic signature.
    /// </summary>
    public bool IsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The authorized QC manager / Qualified Person who signed and released the certificate.
    /// </summary>
    public long? UserSubmittedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the certificate was signed and released.
    /// </summary>
    public DateTime? DateSubmitted { get; set; }

    /// <summary>
    /// Quality assurance release disposition notes, authorized deviations, or release comments.
    /// </summary>
    public string? CommentsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.certificates(id) (nullable). Points to the previous certificate revision that this document supersedes.
    /// </summary>
    public long? CertificateReplacedId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the certificate was officially revoked or cancelled.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who revoked the certificate.
    /// </summary>
    public long? UserCancelledId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the certificate was cancelled.
    /// </summary>
    public DateTime? DateCancelled { get; set; }

    /// <summary>
    /// Mandatory documented justification explaining why the quality certificate was revoked.
    /// </summary>
    public string? CommentsCancelled { get; set; }

    public virtual Certificate? CertificateReplaced { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ControlCode ControlCode { get; set; } = null!;

    public virtual ICollection<Certificate> InverseCertificateReplaced { get; set; } = new List<Certificate>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual Spec Spec { get; set; } = null!;

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }
}
