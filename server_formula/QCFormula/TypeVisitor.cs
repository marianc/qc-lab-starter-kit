using Antlr4.Runtime.Misc;
using QCFormula.ANTLRGenerated;
using System;
using System.Collections.Generic;
using System.Linq;

namespace QCFormula
{
    public class TypeVisitor : QCFormulaBaseVisitor<FormulaReturnType>
    {
        private readonly Dictionary<string, FormulaReturnType> _memory;

        public TypeVisitor()
        {
            _memory = new Dictionary<string, FormulaReturnType>();
        }

        public override FormulaReturnType VisitProg([NotNull] QCFormulaParser.ProgContext context)
        {
            var statements = context.statement();
            if (statements != null && statements.Length > 0)
            {
                foreach (var stmt in statements)
                {
                    Visit(stmt);
                }
            }
            return Visit(context.final_expression());
        }

        public override FormulaReturnType VisitStatement([NotNull] QCFormulaParser.StatementContext context)
        {
            return Visit(context.assignment());
        }

        public override FormulaReturnType VisitAssignment([NotNull] QCFormulaParser.AssignmentContext context)
        {
            string varName = context.ID().GetText();
            FormulaReturnType value = Visit(context.expression());
            _memory[varName] = value;
            return value;
        }

        public override FormulaReturnType VisitFinal_expression([NotNull] QCFormulaParser.Final_expressionContext context)
        {
            return Visit(context.expression());
        }

        public override FormulaReturnType VisitAtomExpr([NotNull] QCFormulaParser.AtomExprContext context)
        {
            return Visit(context.atom());
        }

        public override FormulaReturnType VisitNumberExpr([NotNull] QCFormulaParser.NumberExprContext context)
        {
            return FormulaReturnType.Scalar;
        }

        public override FormulaReturnType VisitVarExpr([NotNull] QCFormulaParser.VarExprContext context)
        {
            string varName = context.ID().GetText();
            if (_memory.ContainsKey(varName))
            {
                return _memory[varName];
            }
            throw new Exception($"Variable '{varName}' is not defined.");
        }

        public override FormulaReturnType VisitParamExpr([NotNull] QCFormulaParser.ParamExprContext context)
        {
            return FormulaReturnType.Scalar;
        }

        public override FormulaReturnType VisitArrayParamExpr([NotNull] QCFormulaParser.ArrayParamExprContext context)
        {
            return FormulaReturnType.Array;
        }

        public override FormulaReturnType VisitParenExpr([NotNull] QCFormulaParser.ParenExprContext context)
        {
            return Visit(context.expression());
        }

        public override FormulaReturnType VisitUnaryMinusExpr([NotNull] QCFormulaParser.UnaryMinusExprContext context)
        {
            return Visit(context.expression());
        }

        private FormulaReturnType ApplyBinaryOperation(FormulaReturnType left, FormulaReturnType right)
        {
            if (left == FormulaReturnType.Array || right == FormulaReturnType.Array)
            {
                return FormulaReturnType.Array;
            }
            return FormulaReturnType.Scalar;
        }

        public override FormulaReturnType VisitPowExpr([NotNull] QCFormulaParser.PowExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitMulDivExpr([NotNull] QCFormulaParser.MulDivExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitAddSubExpr([NotNull] QCFormulaParser.AddSubExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitCompExpr([NotNull] QCFormulaParser.CompExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitEqExpr([NotNull] QCFormulaParser.EqExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitAndExpr([NotNull] QCFormulaParser.AndExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitOrExpr([NotNull] QCFormulaParser.OrExprContext context)
        {
            var left = Visit(context.expression(0));
            var right = Visit(context.expression(1));
            return ApplyBinaryOperation(left, right);
        }

        public override FormulaReturnType VisitFuncCallExpr([NotNull] QCFormulaParser.FuncCallExprContext context)
        {
            string funcName = context.ID().GetText().ToLower();
            List<FormulaReturnType> args = new List<FormulaReturnType>();
            if (context.arg_list() != null)
            {
                args = GetArgTypes(context.arg_list());
            }

            switch (funcName)
            {
                case "sqrt":
                    if (args.Count != 1) throw new Exception("Wrong number of arguments for function 'sqrt'");
                    return args[0];
                
                case "if":
                    if (args.Count != 3) throw new Exception("Wrong number of arguments for function 'if'");
                    if (args.Any(arg => arg == FormulaReturnType.Array)) return FormulaReturnType.Array;
                    return FormulaReturnType.Scalar;

                case "sum":
                    if (args.Count < 1) throw new Exception("SUM function requires at least one argument.");
                    return FormulaReturnType.Scalar;

                case "count":
                    if (args.Count < 1) throw new Exception("COUNT function requires at least one argument.");
                    return FormulaReturnType.Scalar;

                case "avg":
                    if (args.Count < 1) throw new Exception("AVG function requires at least one argument.");
                    return FormulaReturnType.Scalar;

                case "filter":
                    if (args.Count != 2) throw new Exception("Wrong number of arguments for function 'filter'");
                    return FormulaReturnType.Array;

                case "round":
                    if (args.Count < 1 || args.Count > 2) throw new Exception("Wrong number of arguments for function 'round'");
                    return args[0];

                default:
                    throw new Exception($"Unknown method call '{funcName}'.");
            }
        }

        private List<FormulaReturnType> GetArgTypes(QCFormulaParser.Arg_listContext context)
        {
             var exprs = context.expression();
             var results = new List<FormulaReturnType>();
             foreach(var expr in exprs)
             {
                 results.Add(Visit(expr));
             }
             return results;
        }
    }
}
