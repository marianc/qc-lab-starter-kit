using QCFormula;

namespace QCLab.Utils;

public static class FormulaUtils
{
    public static bool CalculateConditionValue(string condition, decimal value)
    {
        var parameters = new Dictionary<string, decimal> { { "value", value } };
        try
        {
            var result = QCFormula.Formula.EvaluateFormula(condition, parameters);
            if (result is decimal d) return d != 0.0m;
            return true;
        }
        catch
        {
            return true;
        }
    }
}
