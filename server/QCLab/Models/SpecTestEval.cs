using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Verification benchmark test cases for specification test conditions (spec_tests.condition). In SpecTestDialog.tsx, authors define test values and expected results (1=pass, 0=fail). The backend recalculates and verifies all cases to guarantee formula correctness before specification activation.
/// </summary>
public partial class SpecTestEval
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the evaluation test row.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.specs(id). The parent specification.
    /// </summary>
    public long SpecId { get; set; }

    /// <summary>
    /// Foreign key referencing public.tests(id). The test being verified.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Test input value passed into the specification condition expression.
    /// </summary>
    public decimal? Value { get; set; }

    /// <summary>
    /// Actual boolean result evaluated by the rule engine (1 for conforming, 0 for non-conforming).
    /// </summary>
    public decimal? Result { get; set; }

    /// <summary>
    /// Expected outcome (1 for pass, 0 for fail) defined by the specification author.
    /// </summary>
    public decimal ExpectedResult { get; set; }

    /// <summary>
    /// Boolean flag. True indicates result matches expected_result.
    /// </summary>
    public bool IsMatch { get; set; }

    /// <summary>
    /// Short descriptive note explaining the test scenario (maximum 20 characters, e.g., &apos;Lower limit fail&apos;, &apos;Target pass&apos;).
    /// </summary>
    public string? Note { get; set; }

    public virtual Spec Spec { get; set; } = null!;

    public virtual SpecTest SpecTest { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
