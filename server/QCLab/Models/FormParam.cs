using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Parameter definitions within a form template. Maps analytical tests (tests) into form fields as raw inputs or calculated formulas. Defines mathematical expressions evaluated by QCFormula, topological evaluation order (nr_ord_calc), array relationships, and conditional pass/fail criteria.
/// </summary>
public partial class FormParam
{
    /// <summary>
    /// Primary key and foreign key referencing public.forms(id). The parent form template.
    /// </summary>
    public long FormId { get; set; }

    /// <summary>
    /// Primary key and foreign key referencing public.tests(id). The analytical test or parameter mapped to this form field.
    /// </summary>
    public long TestId { get; set; }

    /// <summary>
    /// Boolean flag indicating whether this parameter is derived via a mathematical formula (true) or entered as a manual raw measurement (false).
    /// </summary>
    public bool IsCalculated { get; set; }

    /// <summary>
    /// Mathematical expression evaluated by the QCFormula ANTLR engine (e.g., &apos;ROUND(([tare_plus_sample] - [tare_dry]) / [sample_mass] * 100, 4)&apos;). References scalar parameters as [code] and array parameters as [[code]]. Mandatory if is_calculated is true.
    /// </summary>
    public string? Formula { get; set; }

    /// <summary>
    /// Extracted list of test variable codes upon which this formula depends. Populated automatically by the QCFormula dependency resolver.
    /// </summary>
    public string? FormulaDependencies { get; set; }

    /// <summary>
    /// Test code string (maximum 50 characters) identifying an associated array test if this calculation parameter aggregates or relates to array determinations.
    /// </summary>
    public string? CodeRelatedArrays { get; set; }

    /// <summary>
    /// Boolean flag indicating that this parameter possesses an acceptance rule / condition. In FormParamDialog.tsx, when true, condition and condition_note are mandatory, and at least one condition evaluation verification test case is required.
    /// </summary>
    public bool HasCondition { get; set; }

    /// <summary>
    /// Boolean condition expression (maximum 255 characters, e.g., &apos;[value] &gt;= 95.0 &amp;&amp; [value] &lt;= 105.0&apos;). Validated via FormsService.ValidateCondition.
    /// </summary>
    public string? Condition { get; set; }

    /// <summary>
    /// Human-readable specification note or warning text displayed if the condition is not met (maximum 150 characters, e.g., &apos;Between 95.0% and 105.0%&apos;).
    /// </summary>
    public string? ConditionNote { get; set; }

    /// <summary>
    /// Boolean flag specifying whether a value for this parameter is strictly required before the worksheet can be completed.
    /// </summary>
    public bool IsRequired { get; set; }

    /// <summary>
    /// Default preset numeric value (e.g., 1.000 for standard volume, or 0).
    /// </summary>
    public decimal? DefaultValue { get; set; }

    /// <summary>
    /// Topological calculation sequence order. Derived automatically by resolving the Directed Acyclic Graph (DAG) of formula dependencies. Formulas are evaluated strictly in ascending order of nr_ord_calc to guarantee all dependent inputs are calculated prior to consumption.
    /// </summary>
    public long NrOrdCalc { get; set; }

    /// <summary>
    /// Visual display sequence order controlling the arrangement of parameter input rows in the user interface.
    /// </summary>
    public long NrOrd { get; set; }

    public virtual Form Form { get; set; } = null!;

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual Test Test { get; set; } = null!;
}
