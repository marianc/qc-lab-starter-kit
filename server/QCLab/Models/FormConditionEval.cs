using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Benchmark test cases verifying parameter condition logic (form_params.condition). Validates that conditional acceptance rules correctly yield 1 (pass) or 0 (fail) against known test input values.
/// </summary>
public partial class FormConditionEval
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the condition evaluation test row.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.forms(id). The parent form template.
    /// </summary>
    public long FormId { get; set; }

    /// <summary>
    /// Foreign key referencing public.tests(id). The parameter whose condition is being verified.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Test input value passed into the condition expression.
    /// </summary>
    public decimal Value { get; set; }

    /// <summary>
    /// Actual boolean outcome evaluated by the rule engine (1 for true/conforming, 0 for false/non-conforming).
    /// </summary>
    public decimal? Result { get; set; }

    /// <summary>
    /// Expected outcome (1 for pass, 0 for fail) specified by the form author.
    /// </summary>
    public decimal ExpectedResult { get; set; }

    /// <summary>
    /// Boolean flag. True indicates result matches expected_result.
    /// </summary>
    public bool IsMatch { get; set; }

    /// <summary>
    /// Short explanation of the test condition boundary (maximum 20 characters, e.g., &apos;Upper limit&apos;, &apos;Nominal pass&apos;).
    /// </summary>
    public string? Note { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual FormParam FormParam { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
