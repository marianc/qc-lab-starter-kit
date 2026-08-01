using Antlr4.Runtime.Misc;
using QCFormula.ANTLRGenerated;
using System;
using System.Collections.Generic;
using System.Linq;

namespace QCFormula
{
    public class EvalVisitor : QCFormulaBaseVisitor<object>
    {
        private readonly Dictionary<string, decimal> _params;
        private readonly Dictionary<string, object> _memory;
        private readonly Dictionary<string, Func<object[], object>> _functions;

        public EvalVisitor(Dictionary<string, decimal> parameters)
        {
            _params = parameters ?? new Dictionary<string, decimal>();
            _memory = new Dictionary<string, object>();
            _functions = new Dictionary<string, Func<object[], object>>
            {
                { "sqrt", args => { if (args.Length != 1) throw new Exception("Wrong number of arguments for function 'sqrt'"); return Sqrt(args[0]); } },
                { "if", args => { if (args.Length != 3) throw new Exception("Wrong number of arguments for function 'if'"); return If(args[0], args[1], args[2]); } },
                { "sum", args => Sum(args) },
                { "count", args => Count(args) },
                { "avg", args => Avg(args) },
                { "filter", args => { if (args.Length != 2) throw new Exception("Wrong number of arguments for function 'filter'"); return Filter(args[0], args[1]); } },
                { "round", args => Round(args) }
            };
        }

        private object Sqrt(object arg)
        {
            if (arg is List<decimal> list)
            {
                return list.Select(x => (decimal)Math.Sqrt((double)x)).ToList();
            }
            return (decimal)Math.Sqrt((double)Convert.ToDecimal(arg));
        }

        private object If(object cond, object trueVal, object falseVal)
        {
            if (cond is List<decimal> listCond)
            {
                var trueList = AsList(trueVal, listCond.Count);
                var falseList = AsList(falseVal, listCond.Count);
                return listCond.Select((c, i) => c != 0 ? trueList[i] : falseList[i]).ToList();
            }
            return Convert.ToDecimal(cond) != 0 ? trueVal : falseVal;
        }

        private List<decimal> FlattenArgs(object[] args)
        {
            var flat = new List<decimal>();
            foreach (var arg in args)
            {
                if (arg is List<decimal> list)
                {
                    flat.AddRange(list);
                }
                else
                {
                    flat.Add(Convert.ToDecimal(arg));
                }
            }
            return flat;
        }

        private object Sum(object[] args)
        {
            if (args.Length == 0) throw new Exception("SUM function requires at least one argument.");
            var flat = FlattenArgs(args);
            if (flat.Count == 0) throw new Exception("SUM function requires at least one argument (after spreading parameter arrays)");
            return flat.Sum();
        }

        private object Count(object[] args)
        {
            if (args.Length == 0) throw new Exception("COUNT function requires at least one argument.");
            return (decimal)FlattenArgs(args).Count;
        }

        private object Avg(object[] args)
        {
            if (args.Length == 0) throw new Exception("AVG function requires at least one argument.");
            var flat = FlattenArgs(args);
            if (flat.Count == 0) throw new Exception("AVG function requires at least one argument (after spreading parameter arrays)");
            return flat.Average();
        }

        private object Filter(object cond, object data)
        {
            if (!(cond is List<decimal> condList) || !(data is List<decimal> dataList))
            {
                 throw new Exception("FILTER function requires two array arguments.");
            }
            if (condList.Count != dataList.Count)
            {
                throw new Exception("FILTER function requires two array arguments of the same size.");
            }
            return dataList.Where((_, i) => condList[i] != 0).ToList();
        }

        private object Round(object[] args)
        {
            if (args.Length < 1 || args.Length > 2)
            {
                throw new Exception("Wrong number of arguments for function 'round'");
            }

            object expr = args[0];
            object decimalsObj = args.Length == 2 ? args[1] : 0.0;

            return ApplyRound(expr, decimalsObj);
        }

        private object ApplyRound(object val, object decimals)
        {
            if (val is List<decimal> valList && decimals is List<decimal> decList)
            {
                if (valList.Count != decList.Count) throw new Exception("Array sizes must be the same for rounding operation.");
                var result = new List<decimal>();
                for (int i = 0; i < valList.Count; i++)
                {
                    result.Add(RoundHalfUp(valList[i], Convert.ToInt32(decList[i])));
                }
                return result;
            }
            if (val is List<decimal> valList2)
            {
                int decVal = Convert.ToInt32(decimals);
                return valList2.Select(x => RoundHalfUp(x, decVal)).ToList();
            }
            if (decimals is List<decimal> decList2)
            {
                decimal vVal = Convert.ToDecimal(val);
                return decList2.Select(x => RoundHalfUp(vVal, Convert.ToInt32(x))).ToList();
            }
            return RoundHalfUp(Convert.ToDecimal(val), Convert.ToInt32(decimals));
        }

        private static decimal RoundHalfUp(decimal value, int decimals)
        {
            if (decimals >= 0)
            {
                try
                {
                    decimal dVal = value;
                    return (decimal)Math.Round(dVal, decimals, MidpointRounding.AwayFromZero);
                }
                catch
                {
                    decimal factor = (decimal)Math.Pow(10, decimals);
                    return Math.Round(value * factor, MidpointRounding.AwayFromZero) / factor;
                }
            }
            else
            {
                decimal factor = (decimal)Math.Pow(10, -decimals);
                try
                {
                    decimal dVal = value;
                    decimal dFactor = (decimal)factor;
                    return (decimal)(Math.Round(dVal / dFactor, 0, MidpointRounding.AwayFromZero) * dFactor);
                }
                catch
                {
                    return Math.Round(value / factor, MidpointRounding.AwayFromZero) * factor;
                }
            }
        }

        private List<decimal> AsList(object val, int count)
        {
            if (val is List<decimal> list) return list;
            var d = Convert.ToDecimal(val);
            return Enumerable.Repeat(d, count).ToList();
        }

        private object ApplyBinary(object left, object right, Func<decimal, decimal, decimal> op)
        {
            if (left is List<decimal> lList && right is List<decimal> rList)
            {
                if (lList.Count != rList.Count) throw new Exception("Array sizes must be the same for binary operations.");
                return lList.Zip(rList, op).ToList();
            }
            if (left is List<decimal> lList2)
            {
                var rVal = Convert.ToDecimal(right);
                return lList2.Select(x => op(x, rVal)).ToList();
            }
            if (right is List<decimal> rList2)
            {
                var lVal = Convert.ToDecimal(left);
                return rList2.Select(x => op(lVal, x)).ToList();
            }
            return op(Convert.ToDecimal(left), Convert.ToDecimal(right));
        }

        // Visitors

        public override object VisitProg([NotNull] QCFormulaParser.ProgContext context)
        {
            if (context.statement() != null)
            {
                foreach (var stmt in context.statement())
                {
                    Visit(stmt);
                }
            }
            return Visit(context.final_expression());
        }

        public override object VisitStatement([NotNull] QCFormulaParser.StatementContext context)
        {
            return Visit(context.assignment());
        }

        public override object VisitAssignment([NotNull] QCFormulaParser.AssignmentContext context)
        {
            string varName = context.ID().GetText();
            object val = Visit(context.expression());
            _memory[varName] = val;
            return val;
        }

        public override object VisitFinal_expression([NotNull] QCFormulaParser.Final_expressionContext context)
        {
            return Visit(context.expression());
        }

        public override object VisitAtomExpr([NotNull] QCFormulaParser.AtomExprContext context)
        {
            return Visit(context.atom());
        }

        public override object VisitNumberExpr([NotNull] QCFormulaParser.NumberExprContext context)
        {
            return decimal.Parse(context.NUMBER().GetText());
        }

        public override object VisitVarExpr([NotNull] QCFormulaParser.VarExprContext context)
        {
            string name = context.ID().GetText();
            if (_memory.ContainsKey(name)) return _memory[name];
            throw new Exception($"Variable '{name}' is not defined.");
        }

        public override object VisitParamExpr([NotNull] QCFormulaParser.ParamExprContext context)
        {
            string name = context.ID().GetText();
            if (_params.ContainsKey(name)) return _params[name];
            throw new Exception($"Parameter '{name}' is not provided.");
        }

        public override object VisitArrayParamExpr([NotNull] QCFormulaParser.ArrayParamExprContext context)
        {
            string name = context.ID().GetText();
            // Logic to collect arr__0, arr__1, etc.
            string prefix = $"{name}__";
            var keys = _params.Keys.Where(k => k.StartsWith(prefix) && !k.Substring(prefix.Length).Contains("__")).ToList();
            keys.Sort((a, b) => {
                int na = int.Parse(a.Substring(prefix.Length));
                int nb = int.Parse(b.Substring(prefix.Length));
                return na.CompareTo(nb);
            });
            return keys.Select(k => _params[k]).ToList();
        }

        public override object VisitParenExpr([NotNull] QCFormulaParser.ParenExprContext context)
        {
            return Visit(context.expression());
        }

        public override object VisitUnaryMinusExpr([NotNull] QCFormulaParser.UnaryMinusExprContext context)
        {
            var val = Visit(context.expression());
            if (val is List<decimal> list) return list.Select(x => -x).ToList();
            return -Convert.ToDecimal(val);
        }

        public override object VisitPowExpr([NotNull] QCFormulaParser.PowExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinary(left, right, (a, b) => (decimal)Math.Pow((double)a, (double)b));
        }

        public override object VisitMulDivExpr([NotNull] QCFormulaParser.MulDivExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            
            if (context.T_MUL() != null)
            {
                 return ApplyBinary(left, right, (a, b) => a * b);
            }

            // Division check
            if (right is List<decimal> rList)
            {
                if (rList.Any(x => x == 0)) throw new DivideByZeroException("ZeroDivisionError");
            }
            else
            {
                if (Convert.ToDecimal(right) == 0) throw new DivideByZeroException("ZeroDivisionError");
            }

            return ApplyBinary(left, right, (a, b) => a / b);
        }

        public override object VisitAddSubExpr([NotNull] QCFormulaParser.AddSubExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinary(left, right, (a, b) => context.T_ADD() != null ? a + b : a - b);
        }

        public override object VisitCompExpr([NotNull] QCFormulaParser.CompExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            Func<decimal, decimal, decimal> op = (a, b) => 0;

            if (context.T_GT() != null) op = (a, b) => a > b ? 1 : 0;
            else if (context.T_GTE() != null) op = (a, b) => a >= b ? 1 : 0;
            else if (context.T_LT() != null) op = (a, b) => a < b ? 1 : 0;
            else if (context.T_LTE() != null) op = (a, b) => a <= b ? 1 : 0;

            return ApplyBinary(left, right, op);
        }

        public override object VisitEqExpr([NotNull] QCFormulaParser.EqExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            Func<decimal, decimal, decimal> op = (a, b) => 0;
            const decimal epsilon = 0.0000000000000000000000000001m;

            if (context.T_EQ() != null) op = (a, b) => Math.Abs(a - b) < epsilon ? 1 : 0; // decimal equality
            else if (context.T_NEQ() != null) op = (a, b) => Math.Abs(a - b) >= epsilon ? 1 : 0;

            return ApplyBinary(left, right, op);
        }

        public override object VisitAndExpr([NotNull] QCFormulaParser.AndExprContext context)
        {
             var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinary(left, right, (a, b) => (a != 0 && b != 0) ? 1 : 0);
        }

        public override object VisitOrExpr([NotNull] QCFormulaParser.OrExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinary(left, right, (a, b) => (a != 0 || b != 0) ? 1 : 0);
        }

        public override object VisitFuncCallExpr([NotNull] QCFormulaParser.FuncCallExprContext context)
        {
            string funcName = context.ID().GetText().ToLower();
            object[] args = new object[0];
            if (context.arg_list() != null)
            {
                 // Manually collect args
                 var exprs = context.arg_list().expression();
                 args = exprs.Select(e => Visit(e)).ToArray();
            }

            if (_functions.ContainsKey(funcName))
            {
                try
                {
                    return _functions[funcName](args);
                }
                catch (Exception e)
                {
                    throw new Exception($"Error executing function '{funcName}': {e.Message}", e);
                }
            }
            throw new Exception($"Unknown method call '{funcName}'.");
        }
    }
}
