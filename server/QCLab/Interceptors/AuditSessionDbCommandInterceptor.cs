using System;
using System.Data.Common;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore.Diagnostics;

namespace QCLab.Interceptors;

public class AuditSessionDbCommandInterceptor : DbCommandInterceptor
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public AuditSessionDbCommandInterceptor(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public override InterceptionResult<DbDataReader> ReaderExecuting(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<DbDataReader> result)
    {
        EnsureSessionVariables(command, eventData);
        return base.ReaderExecuting(command, eventData, result);
    }

    public override ValueTask<InterceptionResult<DbDataReader>> ReaderExecutingAsync(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<DbDataReader> result,
        CancellationToken cancellationToken = default)
    {
        EnsureSessionVariables(command, eventData);
        return base.ReaderExecutingAsync(command, eventData, result, cancellationToken);
    }

    public override InterceptionResult<int> NonQueryExecuting(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<int> result)
    {
        EnsureSessionVariables(command, eventData);
        return base.NonQueryExecuting(command, eventData, result);
    }

    public override ValueTask<InterceptionResult<int>> NonQueryExecutingAsync(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        EnsureSessionVariables(command, eventData);
        return base.NonQueryExecutingAsync(command, eventData, result, cancellationToken);
    }

    public override InterceptionResult<object> ScalarExecuting(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<object> result)
    {
        EnsureSessionVariables(command, eventData);
        return base.ScalarExecuting(command, eventData, result);
    }

    public override ValueTask<InterceptionResult<object>> ScalarExecutingAsync(
        DbCommand command,
        CommandEventData eventData,
        InterceptionResult<object> result,
        CancellationToken cancellationToken = default)
    {
        EnsureSessionVariables(command, eventData);
        return base.ScalarExecutingAsync(command, eventData, result, cancellationToken);
    }

    private void EnsureSessionVariables(DbCommand command, CommandEventData eventData)
    {
        // Avoid setting session variables for queries that are already setting them
        if (command.CommandText.StartsWith("SET LOCAL app.current_user_id", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var httpContext = _httpContextAccessor.HttpContext;
        var userIdClaim = httpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        var userId = !string.IsNullOrEmpty(userIdClaim) ? userIdClaim : "1";
        var clientIp = httpContext?.Connection?.RemoteIpAddress?.ToString() ?? "127.0.0.1";
        var reason = httpContext?.Items["AuditReason"] as string ?? "Operation performed via QCLab system API";

        using var setCmd = command.Connection.CreateCommand();
        if (command.Transaction != null)
        {
            setCmd.Transaction = command.Transaction;
        }
        setCmd.CommandText = $"SET LOCAL app.current_user_id = '{userId}'; " +
                             $"SET LOCAL app.reason_for_change = '{SanitizeSqlString(reason)}'; " +
                             $"SET LOCAL app.client_ip = '{SanitizeSqlString(clientIp)}';";
        
        if (setCmd.Connection.State != System.Data.ConnectionState.Open)
        {
            setCmd.Connection.Open();
        }
        setCmd.ExecuteNonQuery();
    }

    private static string SanitizeSqlString(string input)
    {
        return input.Replace("'", "''");
    }
}
