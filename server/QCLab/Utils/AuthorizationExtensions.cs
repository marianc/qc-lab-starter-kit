namespace QCLab.Utils;

public static class AuthorizationExtensions
{
    public static RouteHandlerBuilder RequireAdmin(this RouteHandlerBuilder builder)
    {
        return builder.RequireAuthorization("AdminOnly");
    }

    public static RouteGroupBuilder RequireAdmin(this RouteGroupBuilder builder)
    {
        return builder.RequireAuthorization("AdminOnly");
    }

    public static RouteHandlerBuilder RequireQcPers(this RouteHandlerBuilder builder)
    {
        return builder.RequireAuthorization("QcPersOnly");
    }

    public static RouteGroupBuilder RequireQcPers(this RouteGroupBuilder builder)
    {
        return builder.RequireAuthorization("QcPersOnly");
    }

    public static RouteHandlerBuilder RequireLabOrQcPers(this RouteHandlerBuilder builder)
    {
        return builder.RequireAuthorization("LabOrQcPersOnly");
    }

    public static RouteGroupBuilder RequireLabOrQcPers(this RouteGroupBuilder builder)
    {
        return builder.RequireAuthorization("LabOrQcPersOnly");
    }

    public static RouteHandlerBuilder RequireLabPers(this RouteHandlerBuilder builder)
    {
        return builder.RequireAuthorization("LabPersOnly");
    }

    public static RouteGroupBuilder RequireLabPers(this RouteGroupBuilder builder)
    {
        return builder.RequireAuthorization("LabPersOnly");
    }

    public static RouteHandlerBuilder RequireRole(this RouteHandlerBuilder builder, params string[] roles)
    {
        return builder.RequireAuthorization(policy => policy.RequireAssertion(ctx => roles.Any(r => ctx.User.IsInRole(r))));
    }

    public static RouteGroupBuilder RequireRole(this RouteGroupBuilder builder, params string[] roles)
    {
        return builder.RequireAuthorization(policy => policy.RequireAssertion(ctx => roles.Any(r => ctx.User.IsInRole(r))));
    }
}
