using System;
using System.Collections.Generic;

namespace QCLab.Models;

/// <summary>
/// User accounts and role-based access control table for laboratory personnel, QC managers, and system administrators. Maintains authentication credentials, session tracking, account security (lockout, password expiration), and soft-deletion status for GxP auditability.
/// </summary>
public partial class User
{
    /// <summary>
    /// Primary key. Unique 64-bit integer identifier for each laboratory system user.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Unique user login username/handle (3 to 12 characters). Enforced by client regex /^[a-z][a-z0-9_]*[a-z0-9]$/ (must start with a lowercase letter, end with alphanumeric, contain only lowercase letters, digits, or underscores). Used for authentication and audit log displays.
    /// </summary>
    public string Tag { get; set; } = null!;

    /// <summary>
    /// Unique 2 to 3 uppercase alphanumeric identifier (regex /^[A-Z][A-Z0-9]*$/) representing the user&apos;s initials. Displayed on compact laboratory worksheets, test result tags, and sample labels.
    /// </summary>
    public string Code { get; set; } = null!;

    /// <summary>
    /// Unique email address of the user (maximum 50 characters). Validated via standard email format rules.
    /// </summary>
    public string Email { get; set; } = null!;

    /// <summary>
    /// User&apos;s given first name (maximum 50 characters).
    /// </summary>
    public string? FirstName { get; set; }

    /// <summary>
    /// User&apos;s family/surname (maximum 50 characters).
    /// </summary>
    public string? LastName { get; set; }

    /// <summary>
    /// Boolean role flag. When true, grants full administrative privileges including user management, role assignments, system settings, and master data configuration.
    /// </summary>
    public bool IsAdmin { get; set; }

    /// <summary>
    /// Boolean role flag. When true, identifies the user as Laboratory Personnel, granting authorization to execute sample receptions, input raw measurement readings, prepare reagent lots, and operate worksheets.
    /// </summary>
    public bool IsLabPers { get; set; }

    /// <summary>
    /// Boolean role flag. When true, identifies the user as Quality Control Personnel, granting authorization to review, validate, and approve forms, specifications, testing reports, and official quality certificates.
    /// </summary>
    public bool IsQcPers { get; set; }

    /// <summary>
    /// Secure cryptographic salted hash of the user&apos;s authentication password.
    /// </summary>
    public string? PasswordHash { get; set; }

    /// <summary>
    /// Cryptographic salt value applied during password hashing to prevent rainbow table attacks.
    /// </summary>
    public string? PasswordSalt { get; set; }

    /// <summary>
    /// Boolean flag forcing the user to update their password upon next login. Automatically set to true when an administrator creates a user account or executes an administrative password reset via ResetPasswordDialog.tsx.
    /// </summary>
    public bool MustChangePassword { get; set; }

    /// <summary>
    /// Timestamp with time zone when the user&apos;s password was last modified. Used for password aging policies.
    /// </summary>
    public DateTime? DatePasswordChanged { get; set; }

    /// <summary>
    /// Integer counter tracking consecutive failed login attempts. Reset to 0 upon successful login; used to trigger temporary or administrative account lockout after exceeding maximum allowed thresholds.
    /// </summary>
    public int FailedLoginAttempts { get; set; }

    /// <summary>
    /// Boolean flag indicating whether the account is currently locked against login attempts due to repeated authentication failures or manual administrative suspension.
    /// </summary>
    public bool IsLocked { get; set; }

    /// <summary>
    /// Timestamp with time zone indicating when the temporary account lockout expires and authentication attempts may resume.
    /// </summary>
    public DateTime? LockExpiration { get; set; }

    /// <summary>
    /// Unique GUID string representing the user&apos;s active session. Stored in the secure HTTP cookie &apos;QCLabSession_{tenantTag}&apos;. Cleared (set to NULL) upon explicit logout, session expiration, password reset, or account deactivation.
    /// </summary>
    public string? SessionId { get; set; }

    /// <summary>
    /// Timestamp with time zone when the current session_id was generated upon successful login.
    /// </summary>
    public DateTime? DateSessionCreated { get; set; }

    /// <summary>
    /// Timestamp with time zone when the current session_id expires (typically 12 hours from generation). Checked by SessionAuthMiddleware.
    /// </summary>
    public DateTime? DateSessionExpire { get; set; }

    /// <summary>
    /// Cryptographic refresh token string used for renewing API sessions.
    /// </summary>
    public string? RefreshToken { get; set; }

    /// <summary>
    /// Timestamp with time zone when the user profile was originally registered in the system.
    /// </summary>
    public DateTime DateCreated { get; set; }

    /// <summary>
    /// Soft-deletion flag. Under GxP and 21 CFR Part 11 regulations, user records cannot be physically deleted because they are referenced across audit trails, electronic signatures, and test worksheets. True indicates the user is deactivated.
    /// </summary>
    public bool IsObsolete { get; set; }

    /// <summary>
    /// Timestamp with time zone when the user was marked obsolete / deactivated. Cleared to NULL if reactivated.
    /// </summary>
    public DateTime? DateObsolete { get; set; }

    /// <summary>
    /// Mandatory documented explanation recorded when deactivating the user profile. Cleared to NULL if reactivated.
    /// </summary>
    public string? CommentsObsolete { get; set; }

    public virtual ICollection<AuditLog> AuditLogs { get; set; } = new List<AuditLog>();

    public virtual ICollection<Certificate> CertificateUserCancelleds { get; set; } = new List<Certificate>();

    public virtual ICollection<Certificate> CertificateUserSubmitteds { get; set; } = new List<Certificate>();

    public virtual ICollection<ElectronicSignature> ElectronicSignatures { get; set; } = new List<ElectronicSignature>();

    public virtual ICollection<Form> FormUserCancelleds { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormUserSubmitteds { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormUserValidateds { get; set; } = new List<Form>();

    public virtual ICollection<MeasurementParam> MeasurementParamUserCreateds { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementParam> MeasurementParamUserUpdateds { get; set; } = new List<MeasurementParam>();

    public virtual ICollection<MeasurementTest> MeasurementTestUserCreateds { get; set; } = new List<MeasurementTest>();

    public virtual ICollection<MeasurementTest> MeasurementTestUserUpdateds { get; set; } = new List<MeasurementTest>();

    public virtual ICollection<Measurement> MeasurementUserCreateds { get; set; } = new List<Measurement>();

    public virtual ICollection<Measurement> MeasurementUserReporteds { get; set; } = new List<Measurement>();

    public virtual ICollection<Measurement> MeasurementUserUpdateds { get; set; } = new List<Measurement>();

    public virtual ICollection<ReagentLot> ReagentLots { get; set; } = new List<ReagentLot>();

    public virtual ICollection<Reception> ReceptionUserReceiveds { get; set; } = new List<Reception>();

    public virtual ICollection<Reception> ReceptionUserRejecteds { get; set; } = new List<Reception>();

    public virtual ICollection<Reception> ReceptionUserSubmitteds { get; set; } = new List<Reception>();

    public virtual ICollection<Report> ReportUserCancelleds { get; set; } = new List<Report>();

    public virtual ICollection<Report> ReportUserSubmitteds { get; set; } = new List<Report>();

    public virtual ICollection<Spec> SpecUserCancelleds { get; set; } = new List<Spec>();

    public virtual ICollection<Spec> SpecUserSubmitteds { get; set; } = new List<Spec>();
}
