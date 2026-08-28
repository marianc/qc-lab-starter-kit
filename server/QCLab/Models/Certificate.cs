using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Certificate
{
    public long Id { get; set; }

    public long ControlCodeId { get; set; }

    public long SpecId { get; set; }

    public bool IsConformingSpec { get; set; }

    public bool IsConformingUncertainty { get; set; }

    public bool IsSubmitted { get; set; }

    public long? UserSubmittedId { get; set; }

    public DateTime? DateSubmitted { get; set; }

    public string? CommentsSubmitted { get; set; }

    public long? CertificateReplacedId { get; set; }

    public bool IsCancelled { get; set; }

    public long? UserCancelledId { get; set; }

    public DateTime? DateCancelled { get; set; }

    public string? CommentsCancelled { get; set; }

    public virtual Certificate? CertificateReplaced { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ControlCode ControlCode { get; set; } = null!;

    public virtual ICollection<Certificate> InverseCertificateReplaced { get; set; } = new List<Certificate>();

    public virtual Spec Spec { get; set; } = null!;

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }
}
