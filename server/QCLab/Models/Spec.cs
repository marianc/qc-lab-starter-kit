using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Spec
{
    public long Id { get; set; }

    public long MaterialId { get; set; }

    public bool IsSubmitted { get; set; }

    public long? UserSubmittedId { get; set; }

    public DateTime? DateSubmitted { get; set; }

    public string? CommentsSubmitted { get; set; }

    public long? SpecReplacedId { get; set; }

    public bool IsCancelled { get; set; }

    public long? UserCancelledId { get; set; }

    public DateTime? DateCancelled { get; set; }

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
