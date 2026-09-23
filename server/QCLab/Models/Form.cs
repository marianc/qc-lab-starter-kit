using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Form
{
    public long Id { get; set; }

    public long FormGroupId { get; set; }

    public string Version { get; set; } = null!;

    public int DaysActiveForEditing { get; set; }

    public bool IsCustomized { get; set; }

    public string? CustomNav { get; set; }

    public bool IsSubmitted { get; set; }

    public long? UserSubmittedId { get; set; }

    public DateTime? DateSubmitted { get; set; }

    public string? CommentsSubmitted { get; set; }

    public bool IsValidated { get; set; }

    public long? UserValidatedId { get; set; }

    public DateTime? DateValidated { get; set; }

    public string? CommentsValidated { get; set; }

    public bool IsCancelled { get; set; }

    public long? UserCancelledId { get; set; }

    public DateTime? DateCancelled { get; set; }

    public string? CommentsCancelled { get; set; }

    public virtual ICollection<FormConditionEval> FormConditionEvals { get; set; } = new List<FormConditionEval>();

    public virtual ICollection<FormEvalParam> FormEvalParams { get; set; } = new List<FormEvalParam>();

    public virtual ICollection<FormEval> FormEvals { get; set; } = new List<FormEval>();

    public virtual FormGroup FormGroup { get; set; } = null!;

    public virtual ICollection<FormParam> FormParams { get; set; } = new List<FormParam>();

    public virtual ICollection<MeasurementParam> MeasurementParams { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();

    public virtual User? UserCancelled { get; set; }

    public virtual User? UserSubmitted { get; set; }

    public virtual User? UserValidated { get; set; }
}
