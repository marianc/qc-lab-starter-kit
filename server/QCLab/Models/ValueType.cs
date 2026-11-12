using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Static foundational reference table defining data types supported for analytical tests and formula parameters: 1 = &apos;integer&apos; (whole numbers), 2 = &apos;real&apos; (floating point / decimal numbers), 3 = &apos;boolean&apos; (binary pass/fail / true/false), 4 = &apos;enum&apos; (discrete selection options defined in test_enums).
/// </summary>
public partial class ValueType
{
    /// <summary>
    /// Primary key. Unique identifier corresponding to the primitive value type enumeration.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the data type (&apos;integer&apos;, &apos;real&apos;, &apos;boolean&apos;, &apos;enum&apos;). Used by the UI to dynamically render appropriate input controls (number input, checkbox/toggle, or select dropdown) and by the QCFormula engine for type inference.
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
