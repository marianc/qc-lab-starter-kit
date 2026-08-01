using System.Net.Http.Json;
using QCLab.Client.Dtos;
using QCLab.Client.Services.Interfaces;

namespace QCLab.Client.Services;

public class AuthService : IAuthService
{
    private readonly HttpClient _httpClient;

    public AuthService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<UserSessionDto?> Login(LoginRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync("api/auth/login", request);
        if (response.IsSuccessStatusCode)
        {
            return await response.Content.ReadFromJsonAsync<UserSessionDto>();
        }
        return null;
    }

    public async Task Logout()
    {
        await _httpClient.PostAsync("api/auth/logout", null);
    }

    public async Task<UserSessionDto?> GetCurrentUser()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<UserSessionDto>("api/auth/me");
        }
        catch
        {
            return null;
        }
    }

    public async Task<bool> ChangePassword(ChangePasswordDto dto)
    {
        var response = await _httpClient.PostAsJsonAsync("api/auth/change-password", dto);
        return response.IsSuccessStatusCode;
    }
}
