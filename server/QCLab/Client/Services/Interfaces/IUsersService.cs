using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IUsersService
    {
        Task<List<UserDto>> GetAllUsers();
        Task<List<UserInfoDto>> GetUsersInfo();
        Task<UserDto?> GetUser(long id);
        Task<IdDto> CreateUser(CreateUserDto newUser);
        Task UpdateUser(long id, UpdateUserDto userData);
        Task ToggleObsolete(long id, ToggleObsoleteDto dto);
        Task ResetPassword(long id, ResetPasswordDto dto);
    }
}