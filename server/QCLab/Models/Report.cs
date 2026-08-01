using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Report
{
    public long Id { get; set; }

    public long ReceptionId { get; set; }

    public bool IsSubmitted { get; set; }

    public long? UserSubmittedId { get; set; }

    public DateTime? DateSubmitted { get; set; }

    public string? CommentsSubmitted { get; set; }

    public long? ReportReplacedId { get; set; }

    public bool IsCancelled { get; set; }

    public long? UserCancelledId { get; set; }

    public DateTime? DateCancelled { get; set; }

    public string? CommentsCancelled { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ICollection<Report> InverseReportReplaced { get; set; } = new List<Report>();

    public virtual Reception Reception { get; set; } = null!;

    public virtual Report? ReportReplaced { get; set; }

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }
}
