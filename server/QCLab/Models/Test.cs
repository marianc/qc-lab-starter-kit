using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Test
{
    public long Id { get; set; }

    public string Name { get; set; } = null!;

    public string Code { get; set; } = null!;

    public string? Description { get; set; }

    public long TypeId { get; set; }

    public bool IsArray { get; set; }

    public bool IsParam { get; set; }

    public long? UnitId { get; set; }

    public long? NormId { get; set; }

    public string? NormRef { get; set; }

    public bool ForCertification { get; set; }

    public long NrOrd { get; set; }

    public bool IsFormValidated { get; set; }

    public DateTime DateCreated { get; set; }

    public bool IsObsolete { get; set; }

    public DateTime? DateObsolete { get; set; }

    public string? CommentsObsolete { get; set; }

    public virtual ICollection<CertificateTest> CertificateTests { get; set; } = new List<CertificateTest>();

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<FormParam> FormParams { get; set; } = new List<FormParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementTest> MeasurementTests { get; set; } = new List<MeasurementTest>();

    public virtual Norm? Norm { get; set; }

    public virtual ICollection<ReportTest> ReportTests { get; set; } = new List<ReportTest>();

    public virtual ICollection<SpecTestEval> SpecTestEvals { get; set; } = new List<SpecTestEval>();

    public virtual ICollection<SpecTest> SpecTests { get; set; } = new List<SpecTest>();

    public virtual ICollection<TestEnum> TestEnums { get; set; } = new List<TestEnum>();

    public virtual ValueType Type { get; set; } = null!;

    public virtual Unit? Unit { get; set; }

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();

    public virtual ICollection<Equipment> Equipment { get; set; } = new List<Equipment>();

    public virtual ICollection<Material> Materials { get; set; } = new List<Material>();

    public virtual ICollection<Reception> Receptions { get; set; } = new List<Reception>();
}
