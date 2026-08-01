using System.Net.Http.Json;

namespace QCLab.Client.Utils;

public static class ServiceUtils
{
    public static async Task HandleErrorResponse(HttpResponseMessage response)
    {
        string? message = null;
        try
        {
            // Try to read as JSON first
            var error = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
            if (error != null && error.TryGetValue("msg", out var msg))
            {
                message = msg;
            }
        }
        catch
        {
            // If not JSON, try to read as plain text
            try
            {
                var plainError = await response.Content.ReadAsStringAsync();
                if (!string.IsNullOrWhiteSpace(plainError))
                {
                    message = plainError;
                }
            }
            catch { /* Ignore further errors */ }
        }

        if (string.IsNullOrEmpty(message))
        {
            message = $"Server error ({(long)response.StatusCode}: {response.ReasonPhrase})";
        }
        else if (message.Contains("at QCLab.") || message.Contains("System."))
        {
            // If it looks like a stack trace, try to extract just the first meaningful line
            var lines = message.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.RemoveEmptyEntries);
            foreach (var line in lines)
            {
                if (line.Contains(":") && !line.Trim().StartsWith("at "))
                {
                    var parts = line.Split(':', 2);
                    if (parts.Length > 1)
                    {
                        message = parts[1].Trim();
                        break;
                    }
                }
                else if (!line.Trim().StartsWith("at "))
                {
                    message = line.Trim();
                    break;
                }
            }
        }

        throw new Exception(message);
    }
}
