using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// Laboratory sample intake, login, and chain-of-custody tracking table. Captures sample submission, laboratory physical receipt, or rejection. Drives subsequent measurement worksheet creation, testing report issuance, and certificate generation.
/// </summary>
public partial class Reception
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for the sample reception event.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Foreign key referencing public.reception_types(id). Specifies whether this reception represents Certification (1), Verification (2), or Category Verification (3).
    /// </summary>
    public long TypeId { get; set; }

    /// <summary>
    /// Foreign key referencing public.control_codes(id) (nullable). Identifies the physical batch/lot being sampled. Mandatory for Certification and Verification receptions; NULL for Category Verification receptions.
    /// </summary>
    public long? ControlCodeId { get; set; }

    /// <summary>
    /// Free-text description of the sampled material (maximum 50 characters). Used exclusively for Category Verification receptions (type_id = 3) where the sample does not correspond to a formally registered catalog item in public.materials.
    /// </summary>
    public string? MaterialName { get; set; }

    /// <summary>
    /// Foreign key referencing public.categories(id) (nullable). Classifies the sample under an established category for Category Verification receptions (type_id = 3). NULL for standard Certification and Verification receptions.
    /// </summary>
    public long? CategoryId { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the sample reception request has been formally submitted by sampling/production personnel.
    /// </summary>
    public bool IsSubmitted { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The user who submitted the sample reception.
    /// </summary>
    public long? UserSubmittedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the sample reception was formally submitted.
    /// </summary>
    public DateTime? DateSubmitted { get; set; }

    /// <summary>
    /// Optional comments, delivery instructions, or sampling conditions noted by the submitter.
    /// </summary>
    public string? CommentsSubmitted { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the laboratory has physically accepted the sample into custody. Setting this to true automatically marks control_codes.is_reception_received = true (ReceptionsService.ReceiveReception).
    /// </summary>
    public bool IsReceived { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The laboratory analyst who checked in and accepted the physical sample.
    /// </summary>
    public long? UserReceivedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the laboratory physically received the sample.
    /// </summary>
    public DateTime? DateReceived { get; set; }

    /// <summary>
    /// Laboratory intake notes regarding sample integrity, packaging, seals, or temperature upon arrival.
    /// </summary>
    public string? CommentsReceived { get; set; }

    /// <summary>
    /// Boolean status flag. True indicates the laboratory rejected the sample intake (e.g. broken seal, insufficient volume, incorrect storage temperature). A rejected reception cannot be received and requires a mandatory reason.
    /// </summary>
    public bool IsRejected { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id) (nullable). The laboratory user who executed the sample rejection.
    /// </summary>
    public long? UserRejectedId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the sample was rejected.
    /// </summary>
    public DateTime? DateRejected { get; set; }

    /// <summary>
    /// Mandatory documented justification explaining why the sample was rejected by the laboratory.
    /// </summary>
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
