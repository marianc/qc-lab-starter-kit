using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Lookup catalog for metrological calibration outcomes: 1 = &apos;Pass&apos; (metrology results conform fully to manufacturer tolerances and uncertainty limits), 2 = &apos;Fail&apos; (out-of-tolerance calibration requiring instrument repair or retirement), 3 = &apos;Limited Use&apos; (calibrated with restricted operational range or derated accuracy limits).
/// </summary>
public partial class EquipmentCalibrationStatus
{
    /// <summary>
    /// Primary key. Unique identifier for the calibration outcome status.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique name of the calibration status (&apos;Pass&apos;, &apos;Fail&apos;, &apos;Limited Use&apos;).
    /// </summary>
    public string Name { get; set; } = null!;

    public virtual ICollection<EquipmentCalibration> EquipmentCalibrations { get; set; } = new List<EquipmentCalibration>();
}
