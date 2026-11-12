using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Discrete lookup choice options for enum-type analytical tests (value_types.id = 4). When creating a new enum test in TestDialog.tsx, the analyst must supply at least two unique items (parsed from enumListString by newline, comma, or semicolon). Individual items can be added or edited via TestEnumDialog.tsx.
/// </summary>
public partial class TestEnum
{
    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The parent test to which this enumeration item belongs.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Primary key. Integer numeric code stored in measurement tables (measurement_tests.value, measurement_params.value) when this enum option is selected (e.g., 1 for &apos;Clear&apos;, 2 for &apos;Slightly Opalescent&apos;, 3 for &apos;Turbid&apos;).
    /// </summary>
    public long Value { get; set; }

    /// <summary>
    /// Human-readable display label (1 to 50 characters, e.g., &apos;Conforms&apos;, &apos;Positive&apos;, &apos;Clear colorless liquid&apos;) shown in dropdowns and printed on analytical certificates.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Numeric display order index (defaults to 0) controlling the sequence of options in client select menus.
    /// </summary>
    public long NrOrd { get; set; }

    /// <summary>
    /// Soft-deletion flag. When true, hides this enum option from future selection while preserving historical test result interpretation.
    /// </summary>
    public bool IsObsolete { get; set; }

    public virtual Test Test { get; set; } = null!;
}
