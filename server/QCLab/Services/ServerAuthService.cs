using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;

namespace QCLab.Services;

public class ServerAuthService : IAuthService
{
    private readonly QualityControlContext _context;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IWebHostEnvironment _env;

    public ServerAuthService(QualityControlContext context, IHttpContextAccessor httpContextAccessor, IWebHostEnvironment env)
    {
        _context = context;
        _httpContextAccessor = httpContextAccessor;
        _env = env;
    }

    public async Task<UserSessionDto?> Login(LoginRequest request)
    {
        // Check if any user exists
        long userCount = await _context.Users.CountAsync();

        User? user = null;

        if (userCount == 0)
        {
            // First user registration, create as admin
            var strengthCheck = IsStrongPassword(request.Password);
            if (!strengthCheck.isValid)
            {
                // In a real app we might want to return details, but the interface returns UserSessionDto? 
                // We'll return null for now, or we'd need to change the return type to a Result<T>.
                // For this task, assuming valid password or just failing login is acceptable behavior for "Login".
                return null; 
            }

            var passwordSalt = Guid.NewGuid().ToString();
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password + passwordSalt);
            var sessionId = Guid.NewGuid().ToString();
            var now = DateTime.UtcNow;

            user = new User
            {
                Tag = "admin",
                Code = "ADM",
                Email = request.Email,
                IsAdmin = true,
                MustChangePassword = false,
                PasswordHash = passwordHash,
                PasswordSalt = passwordSalt,
                DatePasswordChanged = now,
                DateCreated = now,
                SessionId = sessionId,
                DateSessionCreated = now,
                DateSessionExpire = now.AddHours(12)
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
        }
        else
        {
            user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null || user.IsObsolete)
            {
                return null;
            }

            if (string.IsNullOrEmpty(user.PasswordHash) || string.IsNullOrEmpty(user.PasswordSalt))
            {
                 return null;
            }

            bool isValid = false;
            try 
            {
                isValid = BCrypt.Net.BCrypt.Verify(request.Password + user.PasswordSalt, user.PasswordHash);
            }
            catch
            {
                 return null;
            }

            if (!isValid) return null;

            // Generate Session
            var sessionId = Guid.NewGuid().ToString();
            user.SessionId = sessionId;
            user.DateSessionCreated = DateTime.UtcNow;
            user.DateSessionExpire = DateTime.UtcNow.AddHours(12);
            
            await _context.SaveChangesAsync();
        }

        // Set Cookie
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext != null)
        {
            var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
            var cookieName = $"QCLabSession_{tenantTag}";
            var cookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = _env.IsProduction(),
                SameSite = _env.IsProduction() ? SameSiteMode.Strict : SameSiteMode.Lax,
                Expires = DateTimeOffset.UtcNow.AddHours(12)
            };
            
            httpContext.Response.Cookies.Append(cookieName, user.SessionId!, cookieOptions);
        }

        return MapToDto(user);
    }

    public async Task Logout()
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext != null)
        {
            var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
            var cookieName = $"QCLabSession_{tenantTag}";
            var sessionId = httpContext.Request.Cookies[cookieName];
            if (!string.IsNullOrEmpty(sessionId))
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.SessionId == sessionId);
                if (user != null)
                {
                    user.SessionId = null;
                    user.DateSessionCreated = null;
                    user.DateSessionExpire = null;
                    await _context.SaveChangesAsync();
                }
            }
            
            httpContext.Response.Cookies.Delete(cookieName);
        }
    }

    public async Task<UserSessionDto?> GetCurrentUser()
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null) return null;

        // Try to get from identity first
        if (httpContext.User.Identity?.IsAuthenticated == true)
        {
            var emailClaim = httpContext.User.Claims.FirstOrDefault(c => c.Type == ClaimTypes.Email);
            if (emailClaim != null)
            {
                 var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == emailClaim.Value);
                 if (user != null) return MapToDto(user);
            }
        }
        
        // Fallback to cookie check (useful for React client if middleware hasn't run yet or scheme mismatch)
        var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
        var cookieName = $"QCLabSession_{tenantTag}";
        var sessionId = httpContext.Request.Cookies[cookieName];
        if (!string.IsNullOrEmpty(sessionId))
        {
            var user = await ValidateSession(sessionId);
            if (user != null) return MapToDto(user);
        }

        return null;
    }

    public async Task<bool> ChangePassword(ChangePasswordDto dto)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null || httpContext.User.Identity?.IsAuthenticated != true) return false;

        if (dto.NewPassword != dto.ConfirmPassword) return false;

        var emailClaim = httpContext.User.FindFirst(ClaimTypes.Email);
        if (emailClaim == null) return false;

        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == emailClaim.Value);
        if (user == null) return false;

        bool isValid = false;
        try 
        {
            isValid = BCrypt.Net.BCrypt.Verify(dto.OldPassword + user.PasswordSalt, user.PasswordHash);
        }
        catch
        {
             return false;
        }

        if (!isValid) return false;

        var strengthCheck = IsStrongPassword(dto.NewPassword);
        if (!strengthCheck.isValid) return false;

        var passwordSalt = Guid.NewGuid().ToString();
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword + passwordSalt);

        user.PasswordHash = passwordHash;
        user.PasswordSalt = passwordSalt;
        user.MustChangePassword = false;
        user.DatePasswordChanged = DateTime.UtcNow;

        // Important: Update the session after password change so the user can continue
        // without being logged out by the MustChangePassword check in MainLayout.
        var sessionId = Guid.NewGuid().ToString();
        user.SessionId = sessionId;
        user.DateSessionCreated = DateTime.UtcNow;
        user.DateSessionExpire = DateTime.UtcNow.AddHours(12);

        await _context.SaveChangesAsync();

        // Update the cookie
        if (httpContext != null)
        {
            var tenantTag = Environment.GetEnvironmentVariable("TENANT_TAG") ?? "Default";
            var cookieName = $"QCLabSession_{tenantTag}";
            var cookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = _env.IsProduction(),
                SameSite = _env.IsProduction() ? SameSiteMode.Strict : SameSiteMode.Lax,
                Expires = DateTimeOffset.UtcNow.AddHours(12)
            };
            httpContext.Response.Cookies.Append(cookieName, user.SessionId, cookieOptions);
        }

        return true;
    }

    // Helper: Validate Session for Middleware
    public async Task<User?> ValidateSession(string sessionId)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.SessionId == sessionId);
        if (user == null) return null;

        if (user.DateSessionExpire < DateTime.UtcNow)
        {
             // Expired
             return null;
        }

        return user;
    }

    private UserSessionDto MapToDto(User user)
    {
        var roles = new List<string> { "Default" };
        if (user.IsAdmin) roles.Add("Admin");
        if (user.IsLabPers) roles.Add("LabPers");
        if (user.IsQcPers) roles.Add("QcPers");

        return new UserSessionDto
        {
            Id = user.Id,
            Name = user.Tag,
            Email = user.Email,
            Roles = roles,
            MustChangePassword = user.MustChangePassword
        };
    }

    private (bool isValid, string message) IsStrongPassword(string password)
    {
        if (password.Length < 8)
        {
            return (false, "Password must be at least 8 characters long.");
        }
        if (!Regex.IsMatch(password, "[A-Z]"))
        {
            return (false, "Password must contain at least one uppercase letter.");
        }
        if (!Regex.IsMatch(password, "[a-z]"))
        {
            return (false, "Password must contain at least one lowercase letter.");
        }
        if (!Regex.IsMatch(password, "[0-9]"))
        {
            return (false, "Password must contain at least one number.");
        }
        if (!Regex.IsMatch(password, "[^A-Za-z0-9]"))
        {
            return (false, "Password must contain at least one special character.");
        }

        return (true, "Password is valid.");
    }
}
