using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class EquipmentCalibrationStatus
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public virtual ICollection<EquipmentCalibration> EquipmentCalibrations { get; set; } = new List<EquipmentCalibration>();
}
