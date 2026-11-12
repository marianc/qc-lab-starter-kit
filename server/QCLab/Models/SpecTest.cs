using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Acceptance limits and testing criteria for each analytical test within a specification. Encapsulates executable boolean condition formulas, human-readable specification notes, testing frequency, and ISO/IEC 17025 measurement uncertainty guard-band evaluation rules.
/// </summary>
public partial class SpecTest
{
    /// <summary>
    /// Primary key and foreign key referencing public.specs(id). The parent specification.
    /// </summary>
    public long SpecId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical test evaluated under this specification.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Executable boolean expression string (maximum 255 characters, e.g., &apos;[value] &gt;= 98.0 &amp;&amp; [value] &lt;= 102.0&apos;, &apos;[value] == 1&apos;). Validated on blur in SpecTestDialog.tsx via SpecificationsService.ValidateCondition. Evaluated during certificate generation.
    /// </summary>
    public string Condition { get; set; } = null!;

    /// <summary>
    /// Human-readable specification limit text (maximum 150 characters, e.g., &apos;98.0% - 102.0%&apos;, &apos;Clear colorless liquid&apos;, &apos;NMT 0.5%&apos;). Printed on analytical test reports and Quality Certificates.
    /// </summary>
    public string Note { get; set; } = null!;

    /// <summary>
    /// Boolean flag implementing ISO/IEC 17025 / ILAC-G8 decision rules. When true, certificate evaluation takes expanded measurement uncertainty into account by verifying that both the lower bound [value - U] and upper bound [value + U] satisfy the condition.
    /// </summary>
    public bool UseUncertainty { get; set; }

    /// <summary>
    /// Integer testing frequency rule (e.g., 1 indicates testing is performed on every batch; 5 indicates skip-lot testing every 5 batches).
    /// </summary>
    public int TestFrequency { get; set; }

    public virtual Spec Spec { get; set; } = null!;

    public virtual ICollection<SpecTestEval> SpecTestEvals { get; set; } = new List<SpecTestEval>();

    public virtual Test Test { get; set; } = null!;
}
