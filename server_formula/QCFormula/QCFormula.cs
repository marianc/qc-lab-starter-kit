using Antlr4.Runtime;
using QCFormula.ANTLRGenerated;
using System;
using System.Collections.Generic;

namespace QCFormula
{
    public static class Formula
    {
        public static object EvaluateFormula(string formulaString, Dictionary<string, decimal> parameters)
        {
            var inputStream = new AntlrInputStream(formulaString);
            var lexer = new QCFormulaLexer(inputStream);
            var tokenStream = new CommonTokenStream(lexer);
            var parser = new QCFormulaParser(tokenStream);

            parser.RemoveErrorListeners();
            parser.AddErrorListener(new ThrowingErrorListener());

            var tree = parser.prog();
            var visitor = new EvalVisitor(parameters);
            object result = visitor.Visit(tree);

            if (result == null) throw new Exception("Evaluation resulted in null value.");
            return result;
        }

        public static List<string> ExtractParameters(string formulaString)
        {
            var inputStream = new AntlrInputStream(formulaString);
            var lexer = new QCFormulaLexer(inputStream);
            var tokenStream = new CommonTokenStream(lexer);
            var parser = new QCFormulaParser(tokenStream);

            parser.RemoveErrorListeners();
            parser.AddErrorListener(new ThrowingErrorListener());

            var tree = parser.prog();
            var visitor = new ParamVisitor();
            visitor.Visit(tree);
            return visitor.GetParameters().OrderBy(p => p).ToList();
        }

        public static FormulaReturnType GetFormulaReturnType(string formulaString)
        {
            var inputStream = new AntlrInputStream(formulaString);
            var lexer = new QCFormulaLexer(inputStream);
            var tokenStream = new CommonTokenStream(lexer);
            var parser = new QCFormulaParser(tokenStream);

            parser.RemoveErrorListeners();
            parser.AddErrorListener(new ThrowingErrorListener());

            var tree = parser.prog();
            var visitor = new TypeVisitor();
            return visitor.Visit(tree);
        }

        public static List<string> ReorderParametersByDependencies(List<string> parameters, Dictionary<string, List<string>> dependencies)
        {
            return DependencyResolver.ReorderParameters(parameters, dependencies);
        }

        public static List<string> GetUnusedParametersFromDependencies(List<string> parameters, Dictionary<string, List<string>> dependencies, List<string> output)
        {
            return DependencyResolver.GetUnusedParameters(parameters, dependencies, output);
        }

        private class ThrowingErrorListener : BaseErrorListener
        {
            public override void SyntaxError(System.IO.TextWriter output, IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, string msg, RecognitionException e)
            {
                if (msg.Contains("extraneous input '[['"))
                {
                    throw new Exception("Invalid operation: can not perform arithmetic operations between parameter array and scalar values.");
                }
                throw new Exception("Invalid syntax.");
            }
        }
    }
}
