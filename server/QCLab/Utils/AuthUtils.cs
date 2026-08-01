using System.Text.RegularExpressions;

namespace QCLab.Utils;

public static class AuthUtils
{
    public static (bool isValid, string message) IsStrongPassword(string password)
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
