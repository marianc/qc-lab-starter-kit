using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces;

public interface IAuthService
{
    Task<UserSessionDto?> Login(LoginRequest request);
    Task Logout();
    Task<UserSessionDto?> GetCurrentUser();
    Task<bool> ChangePassword(ChangePasswordDto dto);
}
