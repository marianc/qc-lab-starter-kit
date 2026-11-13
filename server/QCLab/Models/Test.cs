using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Master analytical test definition and calculation parameter dictionary. Defines physical, chemical, and biological tests, as well as intermediate variables used in formulas. Controls measurement data types, replicated array behavior, metrological uncertainty defaults, CRM requirements, norm/SOP method bindings, and validation immutability locks.
/// </summary>
public partial class Test
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the test/parameter definition.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique descriptive name of the test (3 to 50 characters, e.g., &apos;Assay by HPLC&apos;, &apos;Loss on Drying&apos;, &apos;pH at 25°C&apos;). Locked from editing if is_form_validated is true.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Unique identifier token (2 to 50 characters) used as a mathematical variable in QC formulas (e.g., &apos;assay&apos;, &apos;lod_wt_loss&apos;, &apos;ph_val&apos;). Must conform to regex /^(?!.*__)[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]$/ (starts with letter, ends with alphanumeric, only alphanumeric and single underscores). Locked from editing if is_form_validated is true to maintain formula AST parsing validity.
    /// </summary>
    public string Code { get; set; } = null!;

    /// <summary>
    /// Extended explanatory text describing the test scope, analytical principle, or sampling preparation.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Foreign key referencing public.value_types(id). Specifies whether results are stored as integer (1), real (2), boolean (3), or enum (4). Locked from editing if is_form_validated is true.
    /// </summary>
    public long TypeId { get; set; }

    /// <summary>
    /// Boolean flag indicating whether the test yields multiple replicated measurement determinations (e.g., parallel injections, duplicate titrations) rather than a single scalar value. In formulas, arrays are referenced as [[code]]. In TestDialog.tsx, setting is_array to true automatically resets and disables for_certified_reference. Locked from editing if is_form_validated is true.
    /// </summary>
    public bool IsArray { get; set; }

    /// <summary>
    /// Boolean flag designating this test as an intermediate calculation parameter or raw input (e.g. tare weight, sample mass, dilution factor) rather than a reportable specification test. In TestDialog.tsx, setting is_param to true resets and disables for_certification and for_certified_reference; when for_environmental_control is true, is_param is always set to true. Locked from editing if is_form_validated is true.
    /// </summary>
    public bool IsParam { get; set; }

    /// <summary>
    /// Boolean flag designating this test for cleanroom and environmental monitoring (e.g., ambient temperature, relative humidity, air particulates). In TestDialog.tsx, enabling this flag enforces that is_param is always set to true, and resets for_certification and for_certified_reference to false.
    /// </summary>
    public bool ForEnvironmentalControl { get; set; }

    /// <summary>
    /// Boolean flag indicating that this is a critical specification test that must be reported on official Quality Certificates / Certificates of Analysis (COA). In TestDialog.tsx, checking this box automatically defaults relative_uncertainty_pct to 3.00% and default_coverage_factor_k to 2.0 (if null/0), and resets for_environmental_control and is_param to false. Unchecking it resets uncertainty fields to NULL.
    /// </summary>
    public bool ForCertification { get; set; }

    /// <summary>
    /// Expanded relative measurement uncertainty percentage (NUMERIC(5,2), e.g., 3.00 for ±3.00%). Used by the reporting engine to calculate absolute expanded measurement uncertainty: U = (value * relative_uncertainty_pct / 100). Editable only when for_certification is true; automatically cleared to NULL when for_certification is false.
    /// </summary>
    public decimal? RelativeUncertaintyPct { get; set; }

    /// <summary>
    /// Default coverage factor k (NUMERIC(3,1), typically 2.0 corresponding to approximately 95% level of confidence under a normal distribution). Used in accordance with ISO/IEC 17025 and GUM (Guide to the Expression of Uncertainty in Measurement). Cleared to NULL when for_certification is false.
    /// </summary>
    public decimal? DefaultCoverageFactorK { get; set; }

    /// <summary>
    /// Boolean flag enforcing strict metrological traceability. When true, during worksheet execution (SelectCrmDialog.tsx), the analyst cannot manually type an arbitrary numeric value; they must select an active, certified value from a Certified Reference Material (CRM) inventory lot or prior CRM certificate. In TestDialog.tsx, enabling this flag resets and disables is_array, is_param, and for_environmental_control.
    /// </summary>
    public bool ForCertifiedReference { get; set; }

    /// <summary>
    /// Foreign key referencing public.units(id) (nullable). Identifies the default unit of measure associated with this test&apos;s results.
    /// </summary>
    public long? UnitId { get; set; }

    /// <summary>
    /// Foreign key referencing public.norms(id) (nullable). Identifies the governing compendial standard. In TestDialog.tsx, selecting a norm filters available SOPs to those belonging to that norm, and clearing the norm resets norm_ref to NULL, sop_id to NULL, and empties the SOP list.
    /// </summary>
    public long? NormId { get; set; }

    /// <summary>
    /// Textual citation (maximum 50 characters) identifying the exact clause, section, or monograph within the governing norm (e.g., &apos;Ph. Eur. 2.2.3&apos;, &apos;USP &lt;621&gt;&apos;). Enabled in TestDialog.tsx only when norm_id is selected.
    /// </summary>
    public string? NormRef { get; set; }

    /// <summary>
    /// Foreign key referencing public.sops(id) (nullable). Links the test definition to its approved operating procedure. Filtered by norm_id in the client UI.
    /// </summary>
    public long? SopId { get; set; }

    /// <summary>
    /// Boolean validation lock. Automatically set to true by FormsService.ValidateForm when any form containing this test is validated and approved. Once true, the client UI disables and server rejects edits to test name, code, type_id, and is_array to guarantee that validated mathematical formulas and calculation ASTs do not become corrupt or broken.
    /// </summary>
    public bool IsFormValidated { get; set; }

    /// <summary>
    /// Timestamp with time zone when the test definition was locked following form validation approval.
    /// </summary>
    public DateTime? DateFormValidated { get; set; }

    /// <summary>
    /// Default numeric presentation and sorting order index (defaults to 0) used when displaying tests in tables and reports.
    /// </summary>
    public long NrOrd { get; set; }

    /// <summary>
    /// Timestamp with time zone when the test was originally registered.
    /// </summary>
    public DateTime DateCreated { get; set; }

    /// <summary>
    /// Soft-deletion flag. Under GxP requirements, test definitions cannot be physically removed if referenced in historical worksheets, specifications, or certificates. When true, hides the test from new templates and specifications.
    /// </summary>
    public bool IsObsolete { get; set; }

    /// <summary>
    /// Timestamp with time zone when the test was decommissioned. Cleared to NULL if reactivated.
    /// </summary>
    public DateTime? DateObsolete { get; set; }

    /// <summary>
    /// Documented reason recorded when deactivating the test definition. Cleared to NULL if reactivated.
    /// </summary>
    public string? CommentsObsolete { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<FormParam> FormParams { get; set; } = new List<FormParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementTest> MeasurementTests { get; set; } = new List<MeasurementTest>();

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<ReagentSupplierLotCertTest> ReagentSupplierLotCertTests { get; set; } = new List<ReagentSupplierLotCertTest>();

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual Sop? Sop { get; set; }

    public virtual ICollection<SpecTestEval> SpecTestEvals { get; set; } = new List<SpecTestEval>();

    public virtual ICollection<SpecTest> SpecTests { get; set; } = new List<SpecTest>();

    public virtual ICollection<TestEnum> TestEnums { get; set; } = new List<TestEnum>();

    public virtual ValueType Type { get; set; } = null!;

    public virtual Unit? Unit { get; set; }

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();

    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    public virtual ICollection<Material> MaterialsNavigation { get; set; } = new List<Material>();

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
