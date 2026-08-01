using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;
using QCLab.Client.Utils;
using System.Net.Http.Json;

namespace QCLab.Client.Services;

public class ClientUsersService(HttpClient httpClient) : IUsersService
{
    public async Task<List<UserDto>> GetAllUsers()
    {
        var result = await httpClient.GetFromJsonAsync<List<UserDto>>("/api/users");
        return result ?? new List<UserDto>();
    }

    public Task<UserDto?> GetUser(long id) =>
        httpClient.GetFromJsonAsync<UserDto>($"/api/users/{id}");

    public async Task<IdDto> CreateUser(CreateUserDto newUser)
    {
        HttpResponseMessage response = await httpClient.PostAsJsonAsync("/api/users", newUser);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
        return (await response.Content.ReadFromJsonAsync<IdDto>())!;
    }

    public async Task UpdateUser(long id, UpdateUserDto userData)
    {
        var response = await httpClient.PutAsJsonAsync($"/api/users/{id}", userData);
        if (!response.IsSuccessStatusCode) await HandleErrorResponse(response);
    }

    public Task ToggleObsolete(long id, ToggleObsoleteDto dto) =>
        httpClient.PutAsJsonAsync($"/api/users/{id}/toggle_obsolete", dto)!;

    public Task ResetPassword(long id, ResetPasswordDto dto) =>
        httpClient.PutAsJsonAsync($"/api/users/{id}/reset_password", dto)!;

    private Task HandleErrorResponse(HttpResponseMessage response) => ServiceUtils.HandleErrorResponse(response);
}
