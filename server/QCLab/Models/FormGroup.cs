using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class FormGroup
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public long NrOrd { get; set; }

    public bool IsFormValidated { get; set; }

    public virtual ICollection<Form> Forms { get; set; } = new List<Form>();
}
