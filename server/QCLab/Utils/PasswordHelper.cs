using BCrypt.Net;

namespace QCLab.Utils;

public static class PasswordHelper
{
    public static void CreatePasswordHash(string password, out string passwordHash, out string passwordSalt)
    {
        passwordSalt = Guid.NewGuid().ToString();
        passwordHash = BCrypt.Net.BCrypt.HashPassword(password + passwordSalt);
    }

    public static bool VerifyPasswordHash(string password, string storedHash, string storedSalt)
    {
        if (string.IsNullOrEmpty(storedHash) || string.IsNullOrEmpty(storedSalt))
            return false;

        try 
        {
            return BCrypt.Net.BCrypt.Verify(password + storedSalt, storedHash);
        }
        catch
        {
            return false;
        }
    }
}
