using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Master item catalog covering manufactured finished products, raw materials, intermediates, chemical reagents, and certified reference materials (CRMs). Dictates whether an item undergoes standard QC release testing, is tracked as a reagent in lab inventory, or requires strict metrological traceability.
/// </summary>
public partial class Material
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the material.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique descriptive name of the material (3 to 50 characters, e.g., &apos;Aspirin Active Substance&apos;, &apos;Ethanol 96%&apos;, &apos;Potassium Dichromate CRM&apos;). Validated for uniqueness on the server and client.
    /// </summary>
    public string Name { get; set; } = null!;

    /// <summary>
    /// Unique uppercase alphanumeric material code (2 to 10 characters, regex /^[A-Z][A-Z0-9]*$/). Used for inventory identification and batch code generation.
    /// </summary>
    public string Code { get; set; } = null!;

    /// <summary>
    /// Optional text notes detailing chemical grade, storage conditions, or physical specifications.
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// Foreign key referencing public.norms(id) (nullable). Identifies the primary pharmacopeial monograph or compendial standard governing this material.
    /// </summary>
    public long? NormId { get; set; }

    /// <summary>
    /// Boolean flag designating the item as a manufactured finished product eligible for production release and customer Certificate of Analysis generation.
    /// </summary>
    public bool IsProduct { get; set; }

    /// <summary>
    /// Boolean flag designating the item as an incoming raw material, active substance, or excipient requiring intake QC verification.
    /// </summary>
    public bool IsRawMaterial { get; set; }

    /// <summary>
    /// Boolean flag designating the item as a laboratory chemical reagent or volumetric solution. Reagents are filtered out in general views unless the user possesses lab or QC roles (is_lab_pers or is_qc_pers). Managed via ReagentsPage.tsx and reagent_lots.
    /// </summary>
    public bool IsReagent { get; set; }

    /// <summary>
    /// Boolean flag indicating that this material is a Certified Reference Material (CRM) requiring strict metrological traceability and certificate of analysis validation under ISO 17034 / ISO/IEC 17025.
    /// </summary>
    public bool IsCertifiedReference { get; set; }

    /// <summary>
    /// Chemical Abstracts Service (CAS) registry number (maximum 20 characters, e.g., &apos;50-78-2&apos; for Acetylsalicylic acid). Used primarily for chemical identification and reagent safety.
    /// </summary>
    public string? CasNumber { get; set; }

    /// <summary>
    /// Timestamp with time zone when the material was registered in the database.
    /// </summary>
    public DateTime DateCreated { get; set; }

    /// <summary>
    /// Soft-deletion flag. Set via MaterialsService.ToggleObsolete. When true, prevents initiating new sample receptions or specifications. Setting to true stamps date_obsolete with UTC timestamp and stores comments_obsolete; reactivating clears both fields to NULL.
    /// </summary>
    public bool IsObsolete { get; set; }

    /// <summary>
    /// Timestamp with time zone when the material was retired. Cleared to NULL if reactivated.
    /// </summary>
    public DateTime? DateObsolete { get; set; }

    /// <summary>
    /// Mandatory documented justification explaining why the material was marked obsolete. Cleared to NULL if reactivated.
    /// </summary>
    public string? CommentsObsolete { get; set; }

    public virtual ICollection<ControlCode> ControlCodes { get; set; } = new List<ControlCode>();

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<Spec> Specs { get; set; } = new List<Spec>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();

    public virtual ICollection<Test> TestsNavigation { get; set; } = new List<Test>();
}
