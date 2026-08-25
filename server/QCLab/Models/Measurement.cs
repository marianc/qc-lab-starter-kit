using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Measurement
{
    public long Id { get; set; }

    public long ReceptionId { get; set; }

    public long? FormId { get; set; }

    public string? Comments { get; set; }

    public bool IsReported { get; set; }

    public long? UserReportedId { get; set; }

    public bool IsReadonly { get; set; }

    public long UserUpdateId { get; set; }

    public DateTime DateUpdate { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual Form? Form { get; set; }

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementTest> MeasurementTests { get; set; } = new List<MeasurementTest>();

    public virtual Reception Reception { get; set; } = null!;

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual User? UserReported { get; set; }

    public virtual User UserUpdate { get; set; } = null!;

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();
}
