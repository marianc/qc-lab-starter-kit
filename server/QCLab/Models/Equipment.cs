using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Equipment
{
    public long Id { get; set; }

    public string EquipmentCode { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? Manufacturer { get; set; }

    public string? Model { get; set; }

    public string SerialNumber { get; set; } = null!;

    public string? Location { get; set; }

    public long StatusId { get; set; }

    public int? CalibrationIntervalDays { get; set; }

    public DateOnly? NextCalibrationDue { get; set; }

    public DateTime DateCreated { get; set; }

    public virtual ICollection<EquipmentCalibration> EquipmentCalibrations { get; set; } = new List<EquipmentCalibration>();

    public virtual EquipmentStatus Status { get; set; } = null!;

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
