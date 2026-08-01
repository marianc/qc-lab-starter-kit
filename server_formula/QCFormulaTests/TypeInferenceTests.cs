using System;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class TypeInferenceTests
    {
        [Fact]
        public void TestScalarReturnTypes()
        {
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("1"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("1 + 2"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("[p1]"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("[p1] * 2"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("SUM([p1], 10)"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("COUNT([[arr1]])"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("AVG([[arr1]], 5)"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("SQRT(16)"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("IF(1, 10, 20)"));
        }

        [Fact]
        public void TestArrayReturnTypes()
        {
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("[[arr1]]"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("[[arr1]] + 5"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("10 * [[arr1]]"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("[[arr1]] + [[arr2]]"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("SQRT([[arr1]])"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("FILTER([[arr1]] > 0, [[arr1]])"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("IF([[arr1]] > 0, 10, 20)"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("IF(1, [[arr1]], 20)"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("IF(1, 10, [[arr1]])"));
        }

        [Fact]
        public void TestLogicalOperatorsReturnType()
        {
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("1 > 2"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("[[arr1]] > 5"));
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("1 && 0"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("[[arr1]] && [[arr2]]"));
        }

        [Fact]
        public void TestAssignments()
        {
            Assert.Equal(FormulaReturnType.Scalar, Formula.GetFormulaReturnType("a = 5; a + 1"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("a = [[arr1]]; a + 1"));
            Assert.Equal(FormulaReturnType.Array, Formula.GetFormulaReturnType("a = 5; b = [[arr1]]; a + b"));
        }

        [Fact]
        public void TestErrorHandling()
        {
            var exception = Assert.Throws<Exception>(() => Formula.GetFormulaReturnType("x + 1"));
            Assert.Contains("Variable 'x' is not defined.", exception.Message);
        }
    }
}
