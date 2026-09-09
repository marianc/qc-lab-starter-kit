using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Material
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string Code { get; set; } = null!;

    public string? Description { get; set; }

    public long? NormId { get; set; }

    public bool IsProduct { get; set; }

    public bool IsRawMaterial { get; set; }

    public bool IsReagent { get; set; }

    public string? CasNumber { get; set; }

    public DateTime DateCreated { get; set; }

    public bool IsObsolete { get; set; }

    public DateTime? DateObsolete { get; set; }

    public string? CommentsObsolete { get; set; }

    public virtual ICollection<ControlCode> ControlCodes { get; set; } = new List<ControlCode>();

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<Spec> Specs { get; set; } = new List<Spec>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();

    public virtual ICollection<Test> TestsNavigation { get; set; } = new List<Test>();
}
