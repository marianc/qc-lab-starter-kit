using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class CertificateTest
{
    public long CertificateId { get; set; }

    public long ReportId { get; set; }

    public long MeasurementId { get; set; }

    public long TestId { get; set; }

    public int Idx { get; set; }

    public decimal Value { get; set; }

    public int TestCount { get; set; }

    public string NoteSpec { get; set; } = null!;

    public bool IsConformingSpec { get; set; }

    public virtual Certificate Certificate { get; set; } = null!;

    public virtual Measurement Measurement { get; set; } = null!;

    public virtual Report Report { get; set; } = null!;

    public virtual ReportTest ReportTest { get; set; } = null!;

    public virtual Test Test { get; set; } = null!;
}
