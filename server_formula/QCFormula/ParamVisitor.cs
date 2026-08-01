using Antlr4.Runtime.Misc;
using QCFormula.ANTLRGenerated;
using System.Collections.Generic;
using System.Linq;

namespace QCFormula
{
    public class ParamVisitor : QCFormulaBaseVisitor<object>
    {
        private readonly HashSet<string> _parameters;

        public ParamVisitor()
        {
            _parameters = new HashSet<string>();
        }

        public List<string> GetParameters()
        {
            return _parameters.ToList();
        }

        public override object VisitProg([NotNull] QCFormulaParser.ProgContext context)
        {
            return VisitChildren(context);
        }

        public override object VisitParamExpr([NotNull] QCFormulaParser.ParamExprContext context)
        {
            string paramName = context.ID().GetText();
            _parameters.Add(paramName);
            return VisitChildren(context);
        }

        public override object VisitArrayParamExpr([NotNull] QCFormulaParser.ArrayParamExprContext context)
        {
            string paramName = context.ID().GetText();
            _parameters.Add($"{paramName}__"); // Add with '__' suffix to indicate array parameter
            return VisitChildren(context);
        }
    }
}
