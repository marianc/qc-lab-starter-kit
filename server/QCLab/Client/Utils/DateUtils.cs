using System;

namespace QCLab.Client.Utils
{
    public static class DateUtils
    {
        public static string FormatDate(this DateTime? date)
        {
            return date?.ToString("dd.MM.yyyy") ?? string.Empty;
        }
    }
}
