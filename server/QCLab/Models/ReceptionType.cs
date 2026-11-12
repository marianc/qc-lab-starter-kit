using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Lookup table defining the standard workflows for sample intake and laboratory login: 1 = &apos;Certification&apos; (full release testing against active material specification), 2 = &apos;Verification&apos; (custom test subset on an established material), 3 = &apos;Category Verification&apos; (ad-hoc testing of unlisted or experimental samples classified by category).
/// </summary>
public partial class ReceptionType
{
    /// <summary>
    /// Primary key. Numeric identifier of the reception type.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique workflow title (&apos;Certification&apos;, &apos;Verification&apos;, &apos;Category Verification&apos;). Determines client dialog layout (CertificationDialog, VerificationDialog, or CategoryVerificationDialog) and backend test population logic.
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
