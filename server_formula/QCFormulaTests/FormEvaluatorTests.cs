using System;
using System.Collections.Generic;
using Xunit;
using QCFormula;

namespace QCFormulaTests
{
    public class FormEvaluatorTests
    {
        [Fact]
        public void TestEvaluateForm_TestCase1()
        {
            var measurementData = new Dictionary<string, object>
            {
                { "test_h", null },
                { "test_k", 4.0 },
                { "pga", 64.56567 },
                { "pgc", 45.345 },
                { "pgb", new List<decimal> { 64.564m, 73.45675474m, 67.347m, 93.467m } },
                { "pgd", new List<decimal> { 85.43424m, 89.73664m, 78.43346m, 54.5357m } }
            };

            var formulas = new Dictionary<string, string>
            {
                { "test_g", "AVG([[pgb]])" },
                { "test_j", "[[pgb]] * [pga] + [[pgd]] * [pgc]" },
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd" } }
            };

            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var allParams = new List<string>(measurementData.Keys);
            allParams.AddRange(computationData.Keys);
            
            var dependencies = new Dictionary<string, List<string>>();
            foreach (var k in measurementData.Keys) dependencies[k] = new List<string>();
            foreach (var kvp in computationData) dependencies[kvp.Key] = kvp.Value.Dependencies;

            var orderedParameters = Formula.ReorderParametersByDependencies(allParams, dependencies);

            var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, relatedParameterArrays);

            Assert.True(Math.Abs((decimal)results["test_g"] - 74.70868868499998m) < 0.000001m);
            
            var test_j = (List<decimal>)results["test_j"];
            Assert.Equal(4, test_j.Count);
            // Values from prompt: [8042.633530679999,8811.892526613774,7904.869421189999,8507.680794389998]
            Assert.True(Math.Abs(test_j[0] - 8042.633530679999m) < 0.00001m);
            Assert.True(Math.Abs(test_j[1] - 8811.892526613774m) < 0.00001m);
        }

        [Fact]
        public void TestEvaluateForm_TestCase2()
        {
            var measurementData = new Dictionary<string, object>
            {
                { "test_h", 0.0 },
                { "test_k", 4.0 },
                { "pga", 65.767 },
                { "pgb", new List<decimal> { 63.4345m, 34.8767m, 66.423m } },
                { "pgd", new List<decimal> { 34.5345m, 45.6456m, 53.76m } },
                { "pge", new List<decimal> { 2.0m, 3.0m, 1.0m } },
                { "pgf", new List<decimal> { 0.0m, 0.0m, 0.0m } }
            };

            var formulas = new Dictionary<string, string>
            {
                { "test_g", "AVG([[pgb]])" },
                { "test_j", "[[pgb]] * [pga] + [[pgd]] * [pgc] + [[pge]] + [[pgf]]" },
                { "tlb", "IF([test_h],0,1)" },
                { "tlba", "IF([[pgf]],0,1)" },
                { "tme", "[test_k]" },
                { "tmae", "[[pge]]" },
                { "pgc", "COUNT([[pgb]])" }
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd", "pge", "pgf" } }
            };

            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var allParams = new List<string>(measurementData.Keys);
            allParams.AddRange(computationData.Keys);
            
            var dependencies = new Dictionary<string, List<string>>();
            foreach (var k in measurementData.Keys) dependencies[k] = new List<string>();
            foreach (var kvp in computationData) dependencies[kvp.Key] = kvp.Value.Dependencies;

            var orderedParameters = Formula.ReorderParametersByDependencies(allParams, dependencies);

            var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, relatedParameterArrays);

            Assert.True(Math.Abs((decimal)results["test_g"] - 54.91139999999999m) < 0.000001m);
            Assert.Equal(1.0m, (decimal)results["tlb"]);
            Assert.Equal(4.0m, (decimal)results["tme"]);
            Assert.Equal(3.0m, (decimal)results["pgc"]);

            var tlba = (List<decimal>)results["tlba"];
            Assert.Equal(3, tlba.Count);
            Assert.All(tlba, x => Assert.Equal(1.0m, x));

            var tmae = (List<decimal>)results["tmae"];
            Assert.Equal(new List<decimal> { 2, 3, 1 }, tmae);
        }

        [Fact]
        public void TestValidation_OverlappingKeys()
        {
            var measurementData = new Dictionary<string, object> { { "p1", 1.0 } };
            var formulas = new Dictionary<string, string> { { "p1", "1+1" } };
            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var orderedParameters = new List<string> { "p1" };

            var ex = Assert.Throws<ArgumentException>(() => FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, null));
            Assert.Contains("must be disjoint", ex.Message);
        }

        [Fact]
        public void TestValidation_RelatedArraysMissing()
        {
            var measurementData = new Dictionary<string, object> { { "p1", 1.0 } };
            var computationData = new Dictionary<string, FormulaInfo>();
            var orderedParameters = new List<string> { "p1" };
            var related = new Dictionary<string, List<string>> { { "group1", new List<string> { "missing" } } };

            var ex = Assert.Throws<ArgumentException>(() => FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, related));
            Assert.Contains("not present in measurementData", ex.Message);
        }

        [Fact]
        public void TestValidation_RelatedArraysNotArray()
        {
            var measurementData = new Dictionary<string, object> { { "p1", 1.0 } };
            var computationData = new Dictionary<string, FormulaInfo>();
            var orderedParameters = new List<string> { "p1" };
            var related = new Dictionary<string, List<string>> { { "group1", new List<string> { "p1" } } };

            var ex = Assert.Throws<ArgumentException>(() => FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, related));
            Assert.Contains("must be an array", ex.Message);
        }

        [Fact]
        public void TestEvaluation_NullDependency()
        {
            // test_h is null, tlb depends on it. Result should be null (scalar default)
             var measurementData = new Dictionary<string, object>
            {
                { "test_h", null }
            };

            var formulas = new Dictionary<string, string>
            {
                { "tlb", "IF([test_h],0,1)" }
            };

            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var orderedParameters = new List<string> { "test_h", "tlb" };

            var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, null);
            
            Assert.Null(results["tlb"]);
        }

        [Fact]
        public void TestEvaluation_ArrayWithNull()
        {
            // array has null
            var measurementData = new Dictionary<string, object>
            {
                { "arr", new List<decimal?> { 1.0m, null, 3.0m } }
            };

            var formulas = new Dictionary<string, string>
            {
                { "res", "SUM([[arr]])" }
            };

            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var orderedParameters = new List<string> { "arr", "res" };

            var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, null);
            
            // Should be null because SUM returns Scalar, and input validation failed
            Assert.Null(results["res"]);
        }

         [Fact]
        public void TestEvaluation_RelatedArraysSizeMismatch()
        {
            var measurementData = new Dictionary<string, object>
            {
                { "arr1", new List<decimal> { 1, 2 } },
                { "arr2", new List<decimal> { 1, 2, 3 } }
            };

            var formulas = new Dictionary<string, string>
            {
                { "res", "[[arr1]] + [[arr2]]" }
            };

            var related = new Dictionary<string, List<string>> { { "g", new List<string> { "arr1", "arr2" } } };

            var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
            var orderedParameters = new List<string> { "arr1", "arr2", "res" };

            var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, related);
            
            // Should be empty list (Array return type)
            var list = (List<decimal>)results["res"];
            Assert.Empty(list);
        }

        [Fact]
        public void TestToFlatMapAndBack()
        {
            var data = new Dictionary<string, object>
            {
                { "p1", 10.5 },
                { "arr1", new List<decimal> { 1.0m, 2.0m, 3.0m } },
                { "arr2", new List<decimal?> { 4.0m, null, 6.0m } }
            };

            var flat = FormEvaluator.ToFlatMap(data);

            Assert.Equal(10.5m, flat["p1"]);
            Assert.Equal(1.0m, flat["arr1__0"]);
            Assert.Equal(2.0m, flat["arr1__1"]);
            Assert.Equal(3.0m, flat["arr1__2"]);
            Assert.Equal(4.0m, flat["arr2__0"]);
            Assert.False(flat.ContainsKey("arr2__1")); // Null should be skipped
            Assert.Equal(6.0m, flat["arr2__2"]);

            var reconstructed = FormEvaluator.FromFlatMap(flat);

            Assert.Equal(10.5m, (decimal)reconstructed["p1"]);
            
            var rArr1 = (List<decimal?>)reconstructed["arr1"];
            Assert.Equal(3, rArr1.Count);
            Assert.Equal(1.0m, rArr1[0]);
            Assert.Equal(2.0m, rArr1[1]);
            Assert.Equal(3.0m, rArr1[2]);

            var rArr2 = (List<decimal?>)reconstructed["arr2"];
            Assert.Equal(3, rArr2.Count);
            Assert.Equal(4.0m, rArr2[0]);
            Assert.Null(rArr2[1]); // Reconstructed as null
            Assert.Equal(6.0m, rArr2[2]);
        }
    }
}
