using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Input variables and expected calculated outputs for form validation test cases (form_evals). During form verification, the QCFormula engine calculates the actual results for all formulas and compares them against expected_value. If all match, is_match is stamped true.
/// </summary>
public partial class FormEvalParam
{
    /// <summary>
    /// Primary key and foreign key referencing public.form_evals(id). The parent validation test case.
    /// </summary>
    public long EvalId { get; set; }

    /// <summary>
    /// Foreign key referencing public.forms(id). The form template.
    /// </summary>
    public long FormId { get; set; }

    /// <summary>
    /// Foreign key referencing public.tests(id). The parameter under test.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Array determination index (0 for scalar parameters, 0..N for replicated array values).
    /// </summary>
    public int Idx { get; set; }

    /// <summary>
    /// Input test value (for manual parameters) or engine-calculated result (for formula parameters).
    /// </summary>
    public decimal? Value { get; set; }

    /// <summary>
    /// Authoritative pre-calculated benchmark value. Used to verify formula accuracy.
    /// </summary>
    public decimal? ExpectedValue { get; set; }

    /// <summary>
    /// Boolean verification flag. True indicates the calculated formula result matches expected_value within tolerance.
    /// </summary>
    public bool IsMatch { get; set; }

    public virtual FormEval Eval { get; set; } = null!;

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
