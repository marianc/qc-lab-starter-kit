using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Version-controlled dynamic analytical worksheet templates. Encapsulates formula calculation graphs, topological evaluation orders, conditional rules, and software validation datasets. Enforces GxP lifecycle state progression: Draft -&gt; Submitted -&gt; Validated -&gt; Cancelled, accompanied by 21 CFR Part 11 electronic signatures.
/// </summary>
public partial class Form
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the form template.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.form_groups(id). The parent group / test family to which this form template belongs.
    /// </summary>
    public long FormGroupId { get; set; }

    /// <summary>
    /// Version number string (maximum 50 characters, e.g., &apos;1.0&apos;, &apos;2.1&apos;). Unique per form group.
    /// </summary>
    public string Version { get; set; } = null!;

    /// <summary>
    /// Grace period in days (integer, defaults to 10) during which a worksheet instance generated from this form remains editable. Once this elapsed time expires following creation, the worksheet automatically becomes locked (is_readonly = true).
    /// </summary>
    public int DaysActiveForEditing { get; set; }

    /// <summary>
    /// Boolean flag indicating that this form relies on a dedicated, specialized frontend UI component rather than standard auto-rendered grid layout. In FormDialog.tsx, when checked, custom_nav is mandatory.
    /// </summary>
    public bool IsCustomized { get; set; }

    /// <summary>
    /// Frontend component route or navigation tag (e.g., &apos;TestingFormA&apos;) defining the custom layout renderer. Mandatory if is_customized is true; nullable if standard generic rendering is used.
    /// </summary>
    public string? CustomNav { get; set; }

    /// <summary>
    /// Boolean lifecycle flag. True indicates the form template has been finalized and submitted for formal verification.
    /// </summary>
    public bool IsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The form author who submitted the template.
    /// </summary>
    public long? UserSubmittedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the form was submitted.
    /// </summary>
    public DateTime? DateSubmitted { get; set; }

    /// <summary>
    /// Author notes, design rationale, or change summary recorded at submission.
    /// </summary>
    public string? CommentsSubmitted { get; set; }

    /// <summary>
    /// Boolean approval flag. When true, the form is validated for routine production testing. Validation requires that all verification test cases (form_evals) PASS. Approving a form creates an electronic signature, marks form_groups.is_form_validated = true, and locks tests.is_form_validated = true for all referenced tests.
    /// </summary>
    public bool IsValidated { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The QC supervisor / system owner who validated and approved the form.
    /// </summary>
    public long? UserValidatedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when validation approval was granted.
    /// </summary>
    public DateTime? DateValidated { get; set; }

    /// <summary>
    /// Formal validation approval remarks recorded by the QC reviewer.
    /// </summary>
    public string? CommentsValidated { get; set; }

    /// <summary>
    /// Boolean lifecycle flag. True indicates the form template was cancelled or superseded. Cancelled forms cannot be selected for new sample receptions or measurements.
    /// </summary>
    public bool IsCancelled { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who cancelled the form template.
    /// </summary>
    public long? UserCancelledId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the form was cancelled.
    /// </summary>
    public DateTime? DateCancelled { get; set; }

    /// <summary>
    /// Mandatory documented justification explaining why the form was cancelled.
    /// </summary>
    public string? CommentsCancelled { get; set; }

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<FormEval> FormEvals { get; set; } = new List<FormEval>();

    public virtual FormGroup FormGroup { get; set; } = null!;

    public virtual ICollection<FormParam> FormParams { get; set; } = new List<FormParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }

    public virtual User? UserValidated { get; set; }
}
