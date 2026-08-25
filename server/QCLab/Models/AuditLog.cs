using System;
using System.Collections.Generic;
using System.Text.Json;

namespace QCLab.Models;

public partial class AuditLog
{
    public long Id { get; set; }

    public string TableName { get; set; } = null!;

    public JsonElement RecordKeys { get; set; }

    public string Action { get; set; } = null!;

    public string? OldData { get; set; }

    public string? NewData { get; set; }

    public List<string>? ChangedFields { get; set; }

    public long UserId { get; set; }

    public string? ReasonForChange { get; set; }

    public DateTime Timestamp { get; set; }

    public string? ClientIp { get; set; }

    public virtual User User { get; set; } = null!;
}
