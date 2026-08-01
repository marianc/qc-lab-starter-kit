using System.Security.Claims;
using QCLab.Services;

namespace QCLab.Middleware;

public class SessionAuthMiddleware
{
    private readonly RequestDelegate _next;

    public SessionAuthMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ServerAuthService authService)
    {
        var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
        var cookieName = $"QCLabSession_{tenantTag}";
        var sessionId = context.Request.Cookies[cookieName];
        if (!string.IsNullOrEmpty(sessionId))
        {
            var user = await authService.ValidateSession(sessionId);
            if (user != null)
            {
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Tag),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim(ClaimTypes.Role, "Default"),
                    new Claim("MustChangePassword", user.MustChangePassword.ToString().ToLower())
                };
                
                if (user.IsAdmin) claims.Add(new Claim(ClaimTypes.Role, "Admin"));
                if (user.IsLabPers) claims.Add(new Claim(ClaimTypes.Role, "LabPers"));
                if (user.IsQcPers) claims.Add(new Claim(ClaimTypes.Role, "QcPers"));

                var identity = new ClaimsIdentity(claims, "CustomCookie");
                context.User = new ClaimsPrincipal(identity);
            }
        }

        await _next(context);
    }
}
