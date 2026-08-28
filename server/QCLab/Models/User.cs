using System;
using System.Collections.Generic;

namespace QCLab.Models;

public partial class User
{
    public long Id { get; set; }

    public string Tag { get; set; } = null!;

    public string Code { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? FirstName { get; set; }

    public string? LastName { get; set; }

    public bool IsAdmin { get; set; }

    public bool IsLabPers { get; set; }

    public bool IsQcPers { get; set; }

    public string? PasswordHash { get; set; }

    public string? PasswordSalt { get; set; }

    public bool MustChangePassword { get; set; }

    public DateTime? DatePasswordChanged { get; set; }

    public int FailedLoginAttempts { get; set; }

    public bool IsLocked { get; set; }

    public DateTime? LockExpiration { get; set; }

    public string? SessionId { get; set; }

    public DateTime? DateSessionCreated { get; set; }

    public DateTime? DateSessionExpire { get; set; }

    public string? RefreshToken { get; set; }

    public DateTime DateCreated { get; set; }

    public bool IsObsolete { get; set; }

    public DateTime? DateObsolete { get; set; }

    public string? CommentsObsolete { get; set; }

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<Certificate> CertificateUserCancelleds { get; set; } = new List<Certificate>();

    public virtual ICollection<Certificate> CertificateUserSubmitteds { get; set; } = new List<Certificate>();

    public virtual ICollection<ElectronicSignature> ElectronicSignatures { get; set; } = new List<ElectronicSignature>();

    public virtual ICollection<Form> FormUserCancelleds { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormUserSubmitteds { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormUserValidateds { get; set; } = new List<Form>();

    public virtual ICollection<Measurement> MeasurementUserCreateds { get; set; } = new List<Measurement>();

    public virtual ICollection<Measurement> MeasurementUserReporteds { get; set; } = new List<Measurement>();

    public virtual ICollection<Measurement> MeasurementUserUpdates { get; set; } = new List<Measurement>();

    public virtual ICollection<Reception> ReceptionUserReceiveds { get; set; } = new List<Reception>();

    public virtual ICollection<Reception> ReceptionUserRejecteds { get; set; } = new List<Reception>();

    public virtual ICollection<Reception> ReceptionUserSubmitteds { get; set; } = new List<Reception>();

    public virtual ICollection<Report> ReportUserCancelleds { get; set; } = new List<Report>();

    public virtual ICollection<Report> ReportUserSubmitteds { get; set; } = new List<Report>();

    public virtual ICollection<Spec> SpecUserCancelleds { get; set; } = new List<Spec>();

    public virtual ICollection<Spec> SpecUserSubmitteds { get; set; } = new List<Spec>();
}
