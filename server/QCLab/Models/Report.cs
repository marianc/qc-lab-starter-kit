using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Formal analytical Testing Reports compiling completed laboratory measurements for a sample reception. Serves as the laboratory&apos;s technical release document before final quality certification. Governed by formal submission, revision/replacement, and cancellation lifecycles with electronic signatures.
/// </summary>
public partial class Report
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the testing report.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.receptions(id). The sample reception for which this test report is generated.
    /// </summary>
    public long ReceptionId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the test report has been formally signed and submitted by authorized lab personnel. Submitting a report automatically transitions underlying measurements to read-only status.
    /// </summary>
    public bool IsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The laboratory user who submitted the test report.
    /// </summary>
    public long? UserSubmittedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the test report was submitted.
    /// </summary>
    public DateTime? DateSubmitted { get; set; }

    /// <summary>
    /// Technical comments, summary of findings, or analytical caveats recorded at report submission.
    /// </summary>
    public string? CommentsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.reports(id) (nullable). Points to the earlier report revision that this report replaces / amends.
    /// </summary>
    public long? ReportReplacedId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the report was officially invalidated or cancelled.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who cancelled the test report.
    /// </summary>
    public long? UserCancelledId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the report was cancelled.
    /// </summary>
    public DateTime? DateCancelled { get; set; }

    /// <summary>
    /// Mandatory documented justification explaining why the test report was cancelled.
    /// </summary>
    public string? CommentsCancelled { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ICollection<Report> InverseReportReplaced { get; set; } = new List<Report>();

    public virtual Reception Reception { get; set; } = null!;

    public virtual Report? ReportReplaced { get; set; }

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }
}
