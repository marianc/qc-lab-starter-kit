using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Validation benchmark test cases designed to prove the algorithmic accuracy of form formulas under 21 CFR Part 11 software verification rules. Before a form template can be validated (is_validated = true), all defined test cases must evaluate successfully without errors.
/// </summary>
public partial class FormEval
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the validation test case.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.forms(id). The form template being verified.
    /// </summary>
    public long FormId { get; set; }

    /// <summary>
    /// Descriptive title or test scenario name (e.g., &apos;Nominal standard weight test case&apos;, &apos;Boundary condition - maximum LOD&apos;).
    /// </summary>
    public string? Description { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();
}
