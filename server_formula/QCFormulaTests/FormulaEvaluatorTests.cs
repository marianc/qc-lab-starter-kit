using System;
using System.Collections.Generic;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class FormulaEvaluatorTests
    {
        [Fact]
        public void TestSimpleAddition()
        {
            var formulaString = "1 + 2";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(3, result);
        }

        [Fact]
        public void TestSimpleSubtraction()
        {
            var formulaString = "10 - 4";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(6, result);
        }

        [Fact]
        public void TestSimpleMultiplication()
        {
            var formulaString = "3 * 7";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(21, result);
        }

        [Fact]
        public void TestSimpleDivision()
        {
            var formulaString = "20 / 5";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(4, result);
        }

        [Fact]
        public void TestSimplePower()
        {
            var formulaString = "2 ^ 3";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(8, result);
        }

        [Fact]
        public void TestOperatorPrecedence_AdditionAndMultiplication()
        {
            var formulaString = "2 + 3 * 4";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(14, result);
        }

        [Fact]
        public void TestOperatorPrecedence_SubtractionAndDivision()
        {
            var formulaString = "20 - 8 / 2";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(16, result);
        }

        [Fact]
        public void TestParentheses()
        {
            var formulaString = "(2 + 3) * 4";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(20, result);
        }

        [Fact]
        public void TestUnaryMinus_FirstTerm()
        {
            var formulaString = "-10 + 3";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(-7, result);
        }

        [Fact]
        public void TestUnaryMinus_BeforeParenthesis()
        {
            var formulaString = "-(10 + 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(-13, result);
        }

        [Fact]
        public void TestParameters_Subtraction()
        {
            var formulaString = "[p1] - [p2]";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 15 },
                { "p2", 10 }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(5, result);
        }

        [Fact]
        public void TestParameters_Addition()
        {
            var formulaString = "[p1] + [p2]";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 15 },
                { "p2", 10 }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(25, result);
        }

        [Fact]
        public void TestVariablesAndAssignments()
        {
            var formulaString = "a = 10; b = a * 2; b + 5";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(25, result);
        }

        [Fact]
        public void TestUndefinedVariable()
        {
            var formulaString = "x + 10";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("Variable 'x' is not defined", exception.Message);
        }

        [Fact]
        public void TestUndefinedParameter()
        {
            var formulaString = "[p99] + 10";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("Parameter 'p99' is not provided", exception.Message);
        }

        [Fact]
        public void TestComplexFormulas()
        {
            var formulaString = @"
                a = [p1] + [p2] + (234.2 * [p1] - [p2]);
                b = [p3] / [p4] + SQRT([p5] - a);
                b = b + 1;
                IF(a > b, a - b, a + b)
            ";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10.0m },
                { "p2", 20.0m },
                { "p3", 1000.0m },
                { "p4", 5.0m },
                { "p5", 2450.0m }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.True(Math.Abs(result - 2141.1005m) < 0.002m, $"Expected close to 2141.1005, got {result}");
        }

        [Fact]
        public void TestComparisons_GreaterThan()
        {
            var formulaString = "10 > 5";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestComparisons_LessThan()
        {
            var formulaString = "10 < 5";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(0.0m, result);
        }

        [Fact]
        public void TestComparisons_Equality()
        {
            var formulaString = "5 == 5";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestComparisons_Inequality()
        {
            var formulaString = "5 != 10";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_TrueAndTrue()
        {
            var formulaString = "1 && 1";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_TrueAndFalse()
        {
            var formulaString = "1 && 0";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(0.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_FalseOrTrue()
        {
            var formulaString = "0 || 1";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_FalseOrFalse()
        {
            var formulaString = "0 || 0";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(0.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_Precedence()
        {
            var formulaString = "10 > 5 && 2 < 3";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_AndParenthesis()
        {
            var formulaString = "(1 > 0) && (2 < 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestLogicalOperators_OrParenthesis()
        {
            var formulaString = "(1 > 0) || (2 > 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(1.0m, result);
        }

        [Fact]
        public void TestScalarFunctions_SQRT()
        {
            var formulaString = "SQRT(16)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(4.0m, result);
        }

        [Fact]
        public void TestScalarFunctions_IF_True()
        {
            var formulaString = "IF(1, 100, 200)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(100.0m, result);
        }

        [Fact]
        public void TestScalarFunctions_IF_False()
        {
            var formulaString = "IF(0, 100, 200)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(200.0m, result);
        }

        [Fact]
        public void TestScalarFunctions_IF_LogicalExpression()
        {
            var formulaString = "IF(1 > 0, 10, 20)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(10.0m, result);
        }

        [Fact]
        public void TestScalarFunctions_IF_Nested()
        {
            var formulaString = "IF(1 > 2, IF(3 > 4, 1, 2), IF(5 > 4, 3, 4))";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(3.0m, result);
        }

        [Fact]
        public void TestDivisionByZero()
        {
            var formulaString = "10 / 0";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.ThrowsAny<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("ZeroDivisionError", exception.Message);
        }

        [Fact]
        public void TestWrongNumberOfArgs_SQRT()
        {
            var formulaString = "SQRT(4, 5)";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("Wrong number of arguments for function 'sqrt'", exception.Message);
        }

        [Fact]
        public void TestWrongNumberOfArgs_IF_More()
        {
            var formulaString = "IF(0, 100, 200, 300)";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("Wrong number of arguments for function 'if'", exception.Message);
        }

        [Fact]
        public void TestWrongNumberOfArgs_IF_Less()
        {
            var formulaString = "IF(0, 100)";
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("Wrong number of arguments for function 'if'", exception.Message);
        }

        [Fact]
        public void TestSumFunction_NumericArgs()
        {
            var formulaString = "SUM(1, 2, 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(6.0m, result);
        }

        [Fact]
        public void TestSumFunction_ParameterArgs()
        {
            var formulaString = "SUM([p1], [p2])";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10 },
                { "p2", 20 }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(30.0m, result);
        }

        [Fact]
        public void TestSumFunction_MixedArgs()
        {
            var formulaString = "a=5; SUM(a, 10)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(15.0m, result);
        }

        [Fact]
        public void TestCountFunction_NumericArgs()
        {
            var formulaString = "COUNT(1, 2, 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(3.0m, result);
        }

        [Fact]
        public void TestCountFunction_ParameterArgs()
        {
            var formulaString = "COUNT([p1], [p2])";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10 },
                { "p2", 20 }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(2.0m, result);
        }

        [Fact]
        public void TestCountFunction_MixedArgs()
        {
            var formulaString = "a=5; COUNT(a, 10)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(2.0m, result);
        }

        [Fact]
        public void TestAvgFunction_NumericArgs()
        {
            var formulaString = "AVG(1, 2, 3)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(2.0m, result);
        }

        [Fact]
        public void TestAvgFunction_ParameterArgs()
        {
            var formulaString = "AVG([p1], [p2])";
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10 },
                { "p2", 20 }
            };
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(15.0m, result);
        }

        [Fact]
        public void TestAvgFunction_MixedArgs()
        {
            var formulaString = "a=5; AVG(a, 15)";
            var parameters = new Dictionary<string, decimal>();
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(10.0m, result);
        }

        [Fact]
        public void TestArrayParameters()
        {
            var parameters = new Dictionary<string, decimal>
            {
                { "arr1__0", 10 }, { "arr1__1", 20 }, { "arr1__2", 30 },
                { "p1", 5 }
            };

            // SUM([[arr1]])
            var formulaString = "SUM([[arr1]])";
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(60.0m, result);

            // COUNT([[arr1]])
            formulaString = "COUNT([[arr1]])";
            result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(3.0m, result);

            // AVG([[arr1]])
            formulaString = "AVG([[arr1]])";
            result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(20.0m, result);

            // SUM([[arr1]], [p1])
            formulaString = "SUM([[arr1]], [p1])";
            result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(65.0m, result);
        }

        [Fact]
        public void TestEmptyArrayParameter()
        {
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 5 }
            };

            // SUM
            var formulaString = "SUM([[arr_empty]])";
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("SUM function requires at least one argument (after spreading parameter arrays)", exception.Message);

            // COUNT
            formulaString = "COUNT([[arr_empty]])";
            var result = (decimal)Formula.EvaluateFormula(formulaString, parameters);
            Assert.Equal(0.0m, result);

            // AVG
            formulaString = "AVG([[arr_empty]])";
            exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula(formulaString, parameters));
            Assert.Contains("AVG function requires at least one argument (after spreading parameter arrays)", exception.Message);
        }

        [Fact]
        public void TestAggregateFunctions_NoArgs()
        {
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("SUM()", parameters));
            Assert.Contains("SUM function requires at least one argument.", exception.Message);

            exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("COUNT()", parameters));
            Assert.Contains("COUNT function requires at least one argument.", exception.Message);

            exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("AVG()", parameters));
            Assert.Contains("AVG function requires at least one argument.", exception.Message);
        }

        [Fact]
        public void TestInvalidSyntax()
        {
            var parameters = new Dictionary<string, decimal>();
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("a=5; SUM(a, 10", parameters));
            Assert.Contains("Invalid syntax.", exception.Message);

            exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("a=5 SUM(a, 10)", parameters));
            Assert.Contains("Invalid syntax.", exception.Message);
            
            exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("AVERAGE(1, 2, 3)", parameters));
            Assert.Contains("Unknown method call 'average'.", exception.Message);
        }

        [Fact]
        public void TestArrayExpressions()
        {
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10.0m },
                { "p2", 20.0m },
                { "p3", 15.0m },
                { "arr4__0", 0 },
                { "arr4__1", 1 },
                { "arr5_c1__0", 150.0m },
                { "arr5_c1__1", 456.0m },
                { "arr5_c1__2", 656.0m },
                { "arr5_c1__3", 576.0m },
                { "arr5_c2__0", 56.0m },
                { "arr5_c2__1", 897.0m },
                { "arr8__0", 654.0m },
                { "arr8__1", 54.0m },
                { "arr8__2", 567.0m },
                { "arr8__3", 987.0m },
                { "arr9__0", 1 },
                { "arr9__1", 2 }
            };

            // Scalar + Array
            var result = (List<decimal>)Formula.EvaluateFormula("3 + [[arr9]]", parameters);
            Assert.Equal(new List<decimal> { 4, 5 }, result);

            // Array + Array
            result = (List<decimal>)Formula.EvaluateFormula("[[arr9]] + [[arr9]]", parameters);
            Assert.Equal(new List<decimal> { 2, 4 }, result);

            // Different lengths
            var exception = Assert.Throws<Exception>(() => Formula.EvaluateFormula("[[arr8]] + [[arr9]]", parameters));
            Assert.Contains("Array sizes must be the same for binary operations.", exception.Message);

            // Parse array params
            result = (List<decimal>)Formula.EvaluateFormula("[[arr5_c1]]", parameters);
            Assert.Equal(new List<decimal> { 150.0m, 456.0m, 656.0m, 576.0m }, result);

            // Complex formula
            var formulaString = @"
                v = 3 + [[arr5_c1]] - 2 * [[arr8]];
                s = SUM([p1], [p2], [[arr5_c2]], [p3], [[arr8]]);
                s + v
            ";
            result = (List<decimal>)Formula.EvaluateFormula(formulaString, parameters);
            var v = new List<decimal> { -1155, 351, -475, -1395 };
            decimal s = 10 + 20 + 56 + 897 + 15 + 654 + 54 + 567 + 987; // 3260
            for (int i = 0; i < result.Count; i++)
            {
                Assert.Equal(s + v[i], result[i], 3);
            }

            // SQRT with array
            result = (List<decimal>)Formula.EvaluateFormula("SQRT([[arr5_c1]])", parameters);
            var c1 = new List<decimal> { 150.0m, 456.0m, 656.0m, 576.0m };
            for (int i = 0; i < result.Count; i++)
            {
                Assert.Equal((decimal)Math.Sqrt((double)c1[i]), result[i], 3);
            }

            // IF with array
            result = (List<decimal>)Formula.EvaluateFormula("IF([[arr4]], 100, 200)", parameters);
            Assert.Equal(new List<decimal> { 200m, 100m }, result);

            // IF with array option
            result = (List<decimal>)Formula.EvaluateFormula("IF(1 > 2, 100, [[arr9]])", parameters);
            Assert.Equal(new List<decimal> { 1, 2 }, result);

            // IF and array addition
            result = (List<decimal>)Formula.EvaluateFormula("IF(1 > 2, 100, 200) + [[arr9]]", parameters);
            Assert.Equal(new List<decimal> { 201, 202 }, result);

            // Scalar and array power
            result = (List<decimal>)Formula.EvaluateFormula("1 + [p1] ^ [[arr9]]", parameters);
            Assert.Equal(new List<decimal> { 11.0m, 101.0m }, result);
        }

        [Fact]
        public void TestFilterFunction()
        {
            var parameters = new Dictionary<string, decimal>
            {
                { "arr4__0", 0 },
                { "arr4__1", 1 },
                { "arr4__2", 0 },
                { "arr4__3", 1 },
                { "arr8__0", 654.0m },
                { "arr8__1", 54.0m },
                { "arr8__2", 567.0m },
                { "arr8__3", 987.0m }
            };

            // FILTER([[arr4]], [[arr8]])
            var result = (List<decimal>)Formula.EvaluateFormula("FILTER([[arr4]], [[arr8]])", parameters);
            Assert.Equal(new List<decimal> { 54.0m, 987.0m }, result);

            // FILTER([[arr8]] > 600, [[arr8]])
            result = (List<decimal>)Formula.EvaluateFormula("FILTER([[arr8]] > 600, [[arr8]])", parameters);
            Assert.Equal(new List<decimal> { 654.0m, 987.0m }, result);

            // FILTER(([[arr8]] > 600) && ([[arr8]] < 900), [[arr8]])
            result = (List<decimal>)Formula.EvaluateFormula("FILTER(([[arr8]] > 600) && ([[arr8]] < 900), [[arr8]])", parameters);
            Assert.Equal(new List<decimal> { 654.0m }, result);
        }

        [Fact]
        public void TestRoundFunction()
        {
            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10.0m },
                { "p2", 20.0m },
                { "p3", 15.0m },
                { "arr5_c1__0", 150.654634578685445m },
                { "arr5_c1__1", 456.8743235679076565245m },
                { "arr5_c1__2", 656.23434674523461457m },
                { "arr5_c1__3", 576.6674348765533466m },
                { "arr5_c2__0", 56.45786787436757656m },
                { "arr5_c2__1", 897.09734346789078734m },
                { "arr8__0", 654.0m },
                { "arr8__1", 54.0m },
                { "arr8__2", 567.0m },
                { "arr8__3", 987.0m },
                { "arr9__0", 2 },
                { "arr9__1", 3 }
            };

            // ROUND(44.4446)
            var resultScalar1 = (decimal)Formula.EvaluateFormula("ROUND(44.4446)", parameters);
            Assert.Equal(44.0m, resultScalar1);

            // ROUND(44.4446, 1)
            var resultScalar2 = (decimal)Formula.EvaluateFormula("ROUND(44.4446, 1)", parameters);
            Assert.Equal(44.4m, resultScalar2);

            // ROUND([[arr5_c1]])
            var resultList1 = (List<decimal>)Formula.EvaluateFormula("ROUND([[arr5_c1]])", parameters);
            Assert.Equal(new List<decimal> { 151.0m, 457.0m, 656.0m, 577.0m }, resultList1);

            // ROUND([[arr5_c1]], 2)
            var resultList2 = (List<decimal>)Formula.EvaluateFormula("ROUND([[arr5_c1]], 2)", parameters);
            Assert.Equal(new List<decimal> { 150.65m, 456.87m, 656.23m, 576.67m }, resultList2);

            // ROUND([[arr5_c2]], [[arr9]])
            var resultList3 = (List<decimal>)Formula.EvaluateFormula("ROUND([[arr5_c2]], [[arr9]])", parameters);
            Assert.Equal(new List<decimal> { 56.46m, 897.097m }, resultList3);

            // Error cases
            Assert.Throws<Exception>(() => Formula.EvaluateFormula("ROUND()", parameters));
            Assert.Throws<Exception>(() => Formula.EvaluateFormula("ROUND(1, 2, 3)", parameters));
        }
    }
}
