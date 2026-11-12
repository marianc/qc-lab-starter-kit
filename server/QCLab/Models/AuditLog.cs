using System;
using System.Collections.Generic;
using System.Text.Json;

namespace QCLab.Models;

/// <summary>
/// GxP and 21 CFR Part 11 compliant audit trail log table. Automatically populated via the PostgreSQL trigger function &apos;process_audit_log()&apos; whenever INSERT, UPDATE, or DELETE operations occur on critical quality tables (certificates, certificate_tests, forms, form_params, measurements, measurement_params, measurement_tests, reports, report_tests, specs, spec_tests). Application user context and justification are injected into PostgreSQL session variables (&apos;app.current_user_id&apos; and &apos;app.reason_for_change&apos;) by the server DbCommandInterceptor &apos;AuditSessionDbCommandInterceptor&apos;.
/// </summary>
public partial class AuditLog
{
    /// <summary>
    /// Primary key. Unique synthetic 64-bit integer identifier for each audit trail entry.
    /// </summary>
    public long Id { get; set; }

    /// <summary>
    /// Name of the database table where the DML modification took place (e.g., &apos;measurements&apos;, &apos;forms&apos;, &apos;specs&apos;). Populated automatically by the trigger via TG_TABLE_NAME.
    /// </summary>
    public string TableName { get; set; } = null!;

    /// <summary>
    /// JSONB object capturing the primary key column names and values of the audited record (e.g., {&quot;id&quot;: 105} or composite keys like {&quot;form_id&quot;: 2, &quot;test_id&quot;: 14, &quot;idx&quot;: 0}). Enables exact historical row tracking.
    /// </summary>
    public JsonElement RecordKeys { get; set; }

    /// <summary>
    /// DML operation type performed on the record: &apos;INSERT&apos;, &apos;UPDATE&apos;, or &apos;DELETE&apos;. Populated via TG_OP in the audit trigger.
    /// </summary>
    public string Action { get; set; } = null!;

    /// <summary>
    /// JSONB snapshot of the entire table row before the change occurred. Set to NULL for INSERT actions; contains pre-modification state for UPDATE and DELETE actions.
    /// </summary>
    public string? OldData { get; set; }

    /// <summary>
    /// JSONB snapshot of the entire table row after the change occurred. Set to NULL for DELETE actions; contains post-modification state for INSERT and UPDATE actions.
    /// </summary>
    public string? NewData { get; set; }

    /// <summary>
    /// PostgreSQL text array (TEXT[]) listing the column names whose values were modified during an UPDATE operation. Allows rapid filtering and visual highlighting of specific edited fields in the audit viewer (AuditLogsTable.tsx).
    /// </summary>
    public List<string>? ChangedFields { get; set; }

    /// <summary>
    /// Foreign key referencing public.users(id). Identifies the laboratory analyst or QC supervisor who executed the transaction. Sourced from the transaction session variable &apos;app.current_user_id&apos; set by AuditSessionDbCommandInterceptor.
    /// </summary>
    public long UserId { get; set; }

    /// <summary>
    /// Mandatory user-supplied justification for the modification. Captured in the UI via modal dialogs (e.g. CommentDialog) and transferred into PostgreSQL via the session variable &apos;app.reason_for_change&apos; to ensure compliance with 21 CFR Part 11 requirements.
    /// </summary>
    public string? ReasonForChange { get; set; }

    /// <summary>
    /// Timestamp with time zone indicating the exact database transaction time when the audit entry was written. Defaults to clock_timestamp() to capture accurate wall-clock execution time.
    /// </summary>
    public DateTime Timestamp { get; set; }

    /// <summary>
    /// Network IP address (IPv4 or IPv6, up to 45 characters) of the client machine that initiated the API request. Captured by ASP.NET Core HttpContextAccessor and recorded for forensic cybersecurity and compliance traceability.
    /// </summary>
    public string? ClientIp { get; set; }

    public virtual User User { get; set; } = null!;
}
