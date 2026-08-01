using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class Reception
{
    public long Id { get; set; }

    public long TypeId { get; set; }

    public long? ControlCodeId { get; set; }

    public string? MaterialName { get; set; }

    public long? CategoryId { get; set; }

    public bool IsSubmitted { get; set; }

    public long? UserSubmittedId { get; set; }

    public DateTime? DateSubmitted { get; set; }

    public string? CommentsSubmitted { get; set; }

    public bool IsReceived { get; set; }

    public long? UserReceivedId { get; set; }

    public DateTime? DateReceived { get; set; }

    public string? CommentsReceived { get; set; }

    public bool IsRejected { get; set; }

    public long? UserRejectedId { get; set; }

    public DateTime? DateRejected { get; set; }

    public string? CommentsRejected { get; set; }

    public virtual Category? Category { get; set; }

    public virtual ControlCode? ControlCode { get; set; }

    public virtual ICollection<Measurement> Measurements { get; set; } = new List<Measurement>();

    public virtual ICollection<Report> Reports { get; set; } = new List<Report>();

    public virtual ReceptionType Type { get; set; } = null!;

    public virtual User? UserReceived { get; set; }

    public virtual User? UserRejected { get; set; }

    public virtual User? UserSubmitted { get; set; }

    public virtual ICollection<Test> Tests { get; set; } = new List<Test>();
}
