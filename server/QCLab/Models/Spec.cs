using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Product and material quality specifications. Defines release limits, compendial monographs, and acceptance criteria used to judge whether manufactured batches or raw material deliveries conform to registered quality standards. Governed by formal submission, replacement/revision, and cancellation lifecycles with electronic signatures.
/// </summary>
public partial class Spec
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the specification.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.materials(id). The material or product governed by this specification.
    /// </summary>
    public long MaterialId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the specification has been approved and activated for release testing. Only submitted and non-cancelled specifications are active for sample receptions and certificate generation.
    /// </summary>
    public bool IsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The QC authority who approved and submitted the specification.
    /// </summary>
    public long? UserSubmittedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the specification was officially activated.
    /// </summary>
    public DateTime? DateSubmitted { get; set; }

    /// <summary>
    /// Regulatory remarks, change control numbers, or justification recorded at submission.
    /// </summary>
    public string? CommentsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.specs(id) (nullable). Points to the previous specification version that this new revision supersedes.
    /// </summary>
    public long? SpecReplacedId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates this specification has been cancelled or retired.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who cancelled the specification.
    /// </summary>
    public long? UserCancelledId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the specification was cancelled.
    /// </summary>
    public DateTime? DateCancelled { get; set; }

    /// <summary>
    /// Mandatory documented explanation explaining why the specification was cancelled.
    /// </summary>
    public string? CommentsCancelled { get; set; }

    public virtual ICollection<Certificate> Certificates { get; set; } = new List<Certificate>();

    public virtual ICollection<Spec> InverseSpecReplaced { get; set; } = new List<Spec>();

    public virtual Material Material { get; set; } = null!;

    public virtual Spec? SpecReplaced { get; set; }

    public virtual ICollection<SpecTestEval> SpecTestEvals { get; set; } = new List<SpecTestEval>();

    public virtual ICollection<SpecTest> SpecTests { get; set; } = new List<SpecTest>();

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }
}
