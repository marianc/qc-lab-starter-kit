using QCFormula;

namespace QCLab.Utils;

public static class FormulaUtils
{
    public static decimal? CalculateConditionValue(string condition, decimal value)
    {
        var parameters = new Dictionary<string, decimal> { { "value", value } };
        try
        {
            var result = QCFormula.Formula.EvaluateFormula(condition, parameters);
            if (result is decimal d) return (decimal)d;
            if (result is bool b) return b ? 1.0m : 0.0m;
            if (result is long i) return (decimal)i;
            return null;
        }
        catch
        {
            return null;
        }
    }
}
