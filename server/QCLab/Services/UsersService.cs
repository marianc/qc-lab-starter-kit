using Microsoft.EntityFrameworkCore;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Models;
using QCLab.Utils;

namespace QCLab.Services;

public class UsersService : IUsersService
{
    private readonly QualityControlContext _context;

    public UsersService(QualityControlContext context)
    {
        _context = context;
    }

    // GET /users
    public async Task<List<UserDto>> GetAllUsers()
    {
        var users = await _context.Users
            .OrderBy(u => u.Tag)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Tag = u.Tag,
                Code = u.Code,
                Email = u.Email,
                FirstName = u.FirstName,
                LastName = u.LastName,
                IsAdmin = u.IsAdmin,
                IsLabPers = u.IsLabPers,
                IsQcPers = u.IsQcPers,
                MustChangePassword = u.MustChangePassword,
                DateCreated = u.DateCreated,
                DatePasswordChanged = u.DatePasswordChanged,
                IsObsolete = u.IsObsolete,
                DateObsolete = u.DateObsolete,
                CommentsObsolete = u.CommentsObsolete
            }).ToListAsync();

        return users;
    }

    // GET /users/{id}
    public async Task<UserDto?> GetUser(long id)
    {
        var user = await _context.Users
            .Where(u => u.Id == id)
            .Select(u => new UserDto
            {
                Id = u.Id,
                Tag = u.Tag,
                Code = u.Code,
                Email = u.Email,
                FirstName = u.FirstName,
                LastName = u.LastName,
                IsAdmin = u.IsAdmin,
                IsLabPers = u.IsLabPers,
                IsQcPers = u.IsQcPers,
                MustChangePassword = u.MustChangePassword,
                DateCreated = u.DateCreated,
                DatePasswordChanged = u.DatePasswordChanged,
                IsObsolete = u.IsObsolete,
                DateObsolete = u.DateObsolete,
                CommentsObsolete = u.CommentsObsolete
            })
            .FirstOrDefaultAsync();

        return user;
    }

    // POST /users
    public async Task<IdDto> CreateUser(CreateUserDto newUser)
    {
        if (string.IsNullOrEmpty(newUser.Password)) throw new ArgumentException("Password is required");

        var (isValid, message) = AuthUtils.IsStrongPassword(newUser.Password);
        if (!isValid) throw new ArgumentException(message);

        try
        {
            var passwordSalt = Guid.NewGuid().ToString();
            var passwordHash = BCrypt.Net.BCrypt.HashPassword(newUser.Password + passwordSalt);

            var user = new User
            {
                Tag = newUser.Tag,
                Code = newUser.Code ?? string.Empty, 
                Email = newUser.Email,
                FirstName = newUser.FirstName,
                LastName = newUser.LastName,
                IsAdmin = newUser.IsAdmin,
                IsLabPers = newUser.IsLabPers,
                IsQcPers = newUser.IsQcPers,
                PasswordHash = passwordHash,
                PasswordSalt = passwordSalt,
                MustChangePassword = true,
                DatePasswordChanged = DateTime.UtcNow,
                DateCreated = DateTime.UtcNow,
            };
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return new() { Id = user.Id };
        }
        catch (DbUpdateException ex)
        {
            if (ex.InnerException != null && ex.InnerException.Message.Contains("UNIQUE constraint failed"))
            {
                 throw new ArgumentException("User with this email or code already exists");
            }
            throw;
        }
    }

    // PUT /users/{id}
    public async Task UpdateUser(long id, UpdateUserDto userData)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) throw new ArgumentException("User not found");

        user.Tag = userData.Tag;
        if (userData.Code != null) user.Code = userData.Code;

        user.Email = userData.Email;
        user.FirstName = userData.FirstName;
        user.LastName = userData.LastName;
        user.IsAdmin = userData.IsAdmin;
        user.IsLabPers = userData.IsLabPers;
        user.IsQcPers = userData.IsQcPers;
        user.MustChangePassword = userData.MustChangePassword;

        await _context.SaveChangesAsync();
    }

    // PUT /users/{id}/toggle_obsolete
    public async Task ToggleObsolete(long id, ToggleObsoleteDto dto)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null) throw new ArgumentException("User not found");

        user.IsObsolete = dto.IsObsolete;
        user.DateObsolete = dto.IsObsolete ? DateTime.UtcNow : null;
        user.CommentsObsolete = dto.IsObsolete ? dto.Comments : null;

        if (dto.IsObsolete)
        {
            user.SessionId = null;
            user.DateSessionCreated = null;
            user.DateSessionExpire = null;
        }

        await _context.SaveChangesAsync();
    }

    // PUT /users/{id}/reset_password
    public async Task ResetPassword(long id, ResetPasswordDto dto)
    {
        if (string.IsNullOrEmpty(dto.NewPassword) || string.IsNullOrEmpty(dto.ConfirmPassword))
        {
            throw new ArgumentException("New password and confirmation are required");
        }

        if (dto.NewPassword != dto.ConfirmPassword)
        {
            throw new ArgumentException("New password and confirmation do not match");
        }

        var (isValid, message) = AuthUtils.IsStrongPassword(dto.NewPassword);
        if (!isValid)
        {
            throw new ArgumentException(message);
        }

        var user = await _context.Users.FindAsync(id);
        if (user == null) throw new ArgumentException("User not found");

        var newPasswordSalt = Guid.NewGuid().ToString();
        var newPasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword + newPasswordSalt);

        user.PasswordHash = newPasswordHash;
        user.PasswordSalt = newPasswordSalt;
        user.MustChangePassword = true;
        user.DatePasswordChanged = DateTime.UtcNow;

        // Clear session on password reset
        user.SessionId = null;
        user.DateSessionCreated = null;
        user.DateSessionExpire = null;

        await _context.SaveChangesAsync();
    }
}
