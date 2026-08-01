using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class ReportTest
{
    public long ReportId { get; set; }

    public long MeasurementId { get; set; }

    public long TestId { get; set; }

    public int Idx { get; set; }

    public decimal Value { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Report Report { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
