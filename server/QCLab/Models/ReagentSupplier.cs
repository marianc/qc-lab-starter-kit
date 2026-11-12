using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Catalog of external commercial vendors, manufacturers, and distributors of laboratory reagents, solvents, standards, and chemicals (e.g., &apos;Merck&apos;, &apos;Sigma-Aldrich&apos;, &apos;Fisher Scientific&apos;, &apos;VWR&apos;). Can be selected from an existing list or created on-the-fly during supplier lot entry in SupplierLotDialog.tsx.
/// </summary>
public partial class ReagentSupplier
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the reagent supplier.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the supplier company (up to 50 characters). Validated for uniqueness via ReagentsService.ValidateSupplierUniqueness.
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<ReagentSupplierLot> ReagentSupplierLots { get; set; } = new List<ReagentSupplierLot>();
}
