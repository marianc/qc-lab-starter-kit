using System;
using System.Collections.Generic;
using System.Text.Json;

namespace QCLab.Client.Dtos;

public class AuditLogDto
{
    public long Id { get; set; }
    public string TableName { get; set; } = string.Empty;
    public JsonElement RecordKeys { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? OldData { get; set; }
    public string? NewData { get; set; }
    public List<string>? ChangedFields { get; set; }
    public long UserId { get; set; }
    public string UserTag { get; set; } = string.Empty;
    public string? ReasonForChange { get; set; }
    public DateTime Timestamp { get; set; }
    public string? ClientIp { get; set; }
}

public class PaginatedAuditLogsDto
{
    public List<AuditLogDto> AuditLogs { get; set; } = new();
    public long TotalCount { get; set; }
    public int PageSize { get; set; }
    public int CurrentPage { get; set; }
}
