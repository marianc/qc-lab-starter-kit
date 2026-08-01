using System;
using System.Collections.Generic;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class ParameterExtractorTests
    {
        [Fact]
        public void TestExtractParameters_ComplexFormula()
        {
            var formulaString = @"
                // comments
                a = [p1] + [p2] + (234.2 * [p1] - [p2]);
                b = [p3] / [p4] + SQRT([p5] - a);
                b = b + 1;
                s = SUM([[arr7]]);
                IF(a < b && a == b, a +b, s)
            ";
            var expectedParameters = new List<string> { "arr7__", "p1", "p2", "p3", "p4", "p5" };
            var result = Formula.ExtractParameters(formulaString);
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_NoParameters()
        {
            var formulaString = "10 + 20 * 5";
            var result = Formula.ExtractParameters(formulaString);
            Assert.Empty(result);
        }

        [Fact]
        public void TestExtractParameters_ScalarOnly()
        {
            var formulaString = "[paramA] + [paramB] - [paramC]";
            var expectedParameters = new List<string> { "paramA", "paramB", "paramC" }; // Sorted
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_ArrayOnly()
        {
            var formulaString = "SUM([[array1]]) + COUNT([[array2]])";
            var expectedParameters = new List<string> { "array1__", "array2__" };
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_Mixed()
        {
            var formulaString = "[pX] * SUM([[arrY]]) - [pZ]";
            var expectedParameters = new List<string> { "arrY__", "pX", "pZ" }; // Sorted
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_Duplicates()
        {
            var formulaString = "[p1] + [p1] + AVG([[arr1]]) + SUM([[arr1]]) / COUNT([[arr1]])";
            var expectedParameters = new List<string> { "arr1__", "p1" }; // Sorted
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_FunctionArgs()
        {
            var formulaString = "IF([cond], [val1], [val2])";
            var expectedParameters = new List<string> { "cond", "val1", "val2" }; // Sorted
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_Assignments()
        {
            var formulaString = "myVar = [initialVal] * 2; [myVar] + [offset]";
            var expectedParameters = new List<string> { "initialVal", "myVar", "offset" }; // Sorted
            var result = Formula.ExtractParameters(formulaString);
            expectedParameters.Sort();
            Assert.Equal(expectedParameters, result);
        }

        [Fact]
        public void TestExtractParameters_InvalidSyntax()
        {
            var formulaString = "[p1] + (";
            var exception = Assert.Throws<Exception>(() => Formula.ExtractParameters(formulaString));
            Assert.Contains("Invalid syntax", exception.Message);
        }
    }
}
