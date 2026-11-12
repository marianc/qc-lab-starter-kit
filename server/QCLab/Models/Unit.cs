using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Lookup catalog of units of measurement (UOM) utilized across analytical test definitions, laboratory equipment, chemical reagents, and parameter calculations (e.g., &apos;mg&apos;, &apos;mL&apos;, &apos;g/cm3&apos;, &apos;%&apos;, &apos;pH&apos;, &apos;°C&apos;, &apos;rpm&apos;, &apos;AU&apos;).
/// </summary>
public partial class Unit
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the measurement unit.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique symbol or name of the unit of measure (maximum 50 characters, e.g., &apos;mg/kg&apos;, &apos;mPa.s&apos;, &apos;Abs&apos;). Displayed alongside test inputs, results, and specification notes.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Full descriptive name or context for the measurement unit (e.g., &apos;Milligrams per kilogram&apos;, &apos;Degrees Celsius&apos;).
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Timestamp with time zone when the measurement unit record was created in the system.
    /// </summary>
    public DateTime DateCreated { get; set; }

    public virtual ICollection<ReagentLot> ReagentLots { get; set; } = new List<ReagentLot>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
