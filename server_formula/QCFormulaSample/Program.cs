using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using QCFormula;

namespace QCFormulaSample
{
    internal class Program
    {
        static void Main(string[] args)
        {
            RunDemonstration0();
            RunDemonstration1();
            RunDemonstration2();
            RunDemonstration3();
            RunDemonstration4();
            RunDemonstration5();
            RunDemonstration6();
            RunDemonstration7();
            RunDemonstration8();
            RunDemonstration9();
            RunDemonstration10();
        }

        static void RunDemonstration0()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Parser Demonstration (C#) (0) ---");

            string formulaString = "10 + 20";
            var parameters = new Dictionary<string, decimal>();

            Console.WriteLine("\n[1] Formula to be evaluated:");
            Console.WriteLine("------------------------------------\n");
            Console.WriteLine(formulaString.Trim());
            Console.WriteLine("------------------------------------\n");

            Console.WriteLine("\n[2] Parameters provided:");
            Console.WriteLine(JsonSerializer.Serialize(parameters));

            try
            {
                object result = Formula.EvaluateFormula(formulaString, parameters);
                Console.WriteLine($"\n[3] Evaluation Result: {result}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[3] An error occurred during evaluation: {e.Message}");
            }
        }

        static void RunDemonstration1()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Parser Demonstration (C#) (1) ---");

            string formulaString = @"
    // Example formula to demonstrate the parser
    a = [p1] + [p2] + (234.2 * [p1] - [p2]);
    b = [p3] / [p4] + SQRT([p5] - a); // Using a variable 'a' defined above
    b = b + 1;
    
    // The final expression, which is the result of the formula.
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

            Console.WriteLine("\n[1] Formula to be evaluated:");
            Console.WriteLine("------------------------------------\n");
            Console.WriteLine(formulaString.Trim());
            Console.WriteLine("------------------------------------\n");

            Console.WriteLine("\n[2] Parameters provided:");
            Console.WriteLine(JsonSerializer.Serialize(parameters, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                object result = Formula.EvaluateFormula(formulaString, parameters);
                Console.WriteLine($"\n[3] Evaluation Result: {result}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[3] An error occurred during evaluation: {e.Message}");
            }
        }

        static void RunDemonstration2()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Parser Demonstration (C#) (2) ---");

            string formulaString = @"
    // Example formula to demonstrate aggregate functions and array parameters
    a = 3 + 5;
    s = SUM([p1], [p2], [[arr7]], a, [p3], [[arr8]]);
    c = COUNT([[arr7]], [[arr8]]);
    avg_val = AVG([[arr7]]);
    s / c
            ";

            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10.0m },
                { "p2", 20.0m },
                { "p3", 15.0m },
                { "arr7__0", 150.0m },
                { "arr7__1", 456.0m },
                { "arr7__2", 656.0m },
                { "arr8__0", 654.0m },
                { "arr8__1", 54.0m },
                { "arr8__2", 567.0m },
                { "arr8__3", 987.0m }
            };

            Console.WriteLine("\n[1] Formula to be evaluated:");
            Console.WriteLine("------------------------------------\n");
            Console.WriteLine(formulaString.Trim());
            Console.WriteLine("------------------------------------\n");

            Console.WriteLine("\n[2] Parameters provided:");
            Console.WriteLine(JsonSerializer.Serialize(parameters, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                object result = Formula.EvaluateFormula(formulaString, parameters);
                Console.WriteLine($"\n[3] Evaluation Result: {result}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[3] An error occurred during evaluation: {e.Message}");
            }
        }

        static void RunDemonstration3()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Parameter Extraction Demonstration (C#) (3) ---");

            string formulaString = @"
    // comments
    a = [p1] + [p2] + (234.2 * [p1] - [p2]);
    b = [p3] / [p4] + SQRT([p5] - a);
    b = b + 1;
    s = SUM([[arr7]]);
    IF(a < b && a == b, a +b, s)
            ";

            Console.WriteLine("\n[1] Formula to extract parameters from:");
            Console.WriteLine("------------------------------------\n");
            Console.WriteLine(formulaString.Trim());
            Console.WriteLine("------------------------------------\n");

            try
            {
                var parameters = Formula.ExtractParameters(formulaString);
                Console.WriteLine($"\n[2] Extracted Parameters: {JsonSerializer.Serialize(parameters)}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[2] An error occurred during parameter extraction: {e.Message}");
            }
        }

        static void RunDemonstration4()
        {
            Console.WriteLine();
            Console.WriteLine("--- Parameter Reordering Demonstration (C#) (4) ---");

            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() }, { "p2", new List<string>() }, { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() }, { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() }, { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3" } }, { "p12", new List<string>() }
            };

            var cyclicDependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() }, { "p2", new List<string>() }, { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() }, { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() }, { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3", "p5" } }, { "p12", new List<string>() }
            };

            var unknownDependency = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() }, { "p2", new List<string>() }, { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() }, { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() }, { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3", "p17" } }, { "p12", new List<string>() }
            };

            Console.WriteLine("\n[1] Original Parameters:");
            Console.WriteLine(JsonSerializer.Serialize(parameters));
            Console.WriteLine("\n[2] Dependencies:");
            Console.WriteLine(JsonSerializer.Serialize(dependencies, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                var orderedParameters = Formula.ReorderParametersByDependencies(parameters, dependencies);
                Console.WriteLine($"\n[3] Reordered Parameters: {JsonSerializer.Serialize(orderedParameters)}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[3] An error occurred during reordering: {e.Message}");
            }

            Console.WriteLine("\n[4] Cyclic Dependencies:");
            Console.WriteLine(JsonSerializer.Serialize(cyclicDependencies));

            try
            {
                Formula.ReorderParametersByDependencies(parameters, cyclicDependencies);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[5] An error occurred during reordering: {e.Message}");
                Console.WriteLine("------------------------------------\n");
            }

            Console.WriteLine("\n[6] Unknown Dependency:");
            Console.WriteLine(JsonSerializer.Serialize(unknownDependency));

            try
            {
                Formula.ReorderParametersByDependencies(parameters, unknownDependency);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[7] An error occurred during reordering: {e.Message}");
                Console.WriteLine("------------------------------------\n");
            }
        }

        static void RunDemonstration5()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Parser Demonstration (C#) (5) ---");

            string formulaString = @"
    v = 3 + [[arr5_c1]] - 2 * [[arr8]]; // arrays arr5_c1 and arr8 should have the same size otherwise throw error
    s = SUM([p1], [p2], [[arr5_c2]], [p3], [[arr8]]); // aggregate functions 'COUNT', 'SUM' and 'AVG' always return scalar values
    s + v // the result is an array resulted by adding the scalar value to each array item
            ";

            var parameters = new Dictionary<string, decimal>
            {
                { "p1", 10.0m }, { "p2", 20.0m }, { "p3", 15.0m },
                { "arr5_c1__0", 150.0m }, { "arr5_c1__1", 456.0m }, { "arr5_c1__2", 656.0m }, { "arr5_c1__3", 576.0m },
                { "arr5_c2__0", 56.0m }, { "arr5_c2__1", 897.0m },
                { "arr8__0", 654.0m }, { "arr8__1", 54.0m }, { "arr8__2", 567.0m }, { "arr8__3", 987.0m }
            };

            Console.WriteLine("\n[1] Formula to be evaluated:");
            Console.WriteLine("------------------------------------\n");
            Console.WriteLine(formulaString.Trim());
            Console.WriteLine("------------------------------------\n");

            Console.WriteLine("\n[2] Parameters provided:");
            Console.WriteLine(JsonSerializer.Serialize(parameters, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                object result = Formula.EvaluateFormula(formulaString, parameters);
                Console.WriteLine($"\n[3] Evaluation Result: {JsonSerializer.Serialize(result)}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[3] An error occurred during evaluation: {e.Message}");
            }
        }

        static void RunDemonstration6()
        {
            Console.WriteLine();
            Console.WriteLine("--- Unused Parameter Calculation Demonstration (C#) (6) ---");

            var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
            var dependencies = new Dictionary<string, List<string>>
            {
                { "p1", new List<string>() }, { "p2", new List<string>() }, { "p3", new List<string>() },
                { "p4", new List<string> { "p2", "p6", "p11" } },
                { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
                { "p6", new List<string>() }, { "p7", new List<string>() },
                { "p8", new List<string> { "p1", "p2", "p3" } },
                { "p9", new List<string>() }, { "p10", new List<string>() },
                { "p11", new List<string> { "p1", "p2", "p3" } }, { "p12", new List<string>() }
            };
            var output = new List<string> { "p4", "p9", "p10" };

            Console.WriteLine("\n[1] All Parameters:");
            Console.WriteLine(JsonSerializer.Serialize(parameters));
            Console.WriteLine("\n[2] Dependencies:");
            Console.WriteLine(JsonSerializer.Serialize(dependencies, new JsonSerializerOptions { WriteIndented = true }));
            Console.WriteLine("\n[3] Output Parameters:");
            Console.WriteLine(JsonSerializer.Serialize(output));

            try
            {
                var unusedParameters = Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output);
                Console.WriteLine($"\n[4] Unused Parameters: {JsonSerializer.Serialize(unusedParameters)}");
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[4] An error occurred during calculation: {e.Message}");
            }
        }

        static void RunDemonstration7()
        {
            Console.WriteLine();
            Console.WriteLine("--- QCFormula Return Type Detection Demonstration (C#) (7) ---");

            var formulas = new List<string>
            {
                "10 + [p1]",
                "[[arr1]] + 5",
                "SUM([p1], [[arr1]])",
                "FILTER([[arr1]] > 5, [[arr1]])",
                "IF([p1] > 0, [[arr1]], 0)",
                "3 + 5"
            };

            Console.WriteLine("\n[1] Detecting return types:");
            Console.WriteLine("------------------------------------\n");

            foreach (var formula in formulas)
            {
                try
                {
                    var type = Formula.GetFormulaReturnType(formula);
                    Console.WriteLine($"Formula: \"{formula.Trim()}\" -> Type: {type}");
                }
                catch (Exception e)
                {
                    Console.Error.WriteLine($"Error analyzing \"{formula}\": {e.Message}");
                }
            }
            Console.WriteLine("------------------------------------\n");
        }

        static void RunDemonstration8()
        {
            Console.WriteLine();
            Console.WriteLine("--- Form Evaluator Demonstration (C#) (8) ---");

            var measurementData = new Dictionary<string, object>
            {
                { "test_h", 0 },
                { "test_k", 4 },
                { "pga", 65.767 },
                { "pgb", new List<decimal> { 63.4345m, 34.8767m, 66.423m } },
                { "pgd", new List<decimal> { 34.5345m, 45.6456m, 53.76m } },
                { "pge", new List<decimal> { 2, 3, 1 } },
                { "pgf", new List<decimal> { 0, 0, 0 } }
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

            Console.WriteLine("\n[1] Measurement Data:");
            Console.WriteLine(JsonSerializer.Serialize(measurementData, new JsonSerializerOptions { WriteIndented = true }));

            Console.WriteLine("\n[2] Formulas:");
            Console.WriteLine(JsonSerializer.Serialize(formulas, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                // Convert formulas to computation data
                var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);
                
                // Calculate Ordered Parameters
                var allParams = new List<string>(measurementData.Keys);
                allParams.AddRange(computationData.Keys);
                
                var dependencies = new Dictionary<string, List<string>>();
                foreach (var k in measurementData.Keys) dependencies[k] = new List<string>();
                foreach (var kvp in computationData) dependencies[kvp.Key] = kvp.Value.Dependencies;

                var orderedParameters = Formula.ReorderParametersByDependencies(allParams, dependencies);
                Console.WriteLine($"\n[3] Ordered Parameters: {JsonSerializer.Serialize(orderedParameters)}");

                // Evaluate
                var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, relatedParameterArrays);

                Console.WriteLine("\n[4] Evaluation Results:");
                Console.WriteLine(JsonSerializer.Serialize(results, new JsonSerializerOptions { WriteIndented = true }));
                Console.WriteLine("------------------------------------\n");
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[4] An error occurred during form evaluation: {e.Message}");
                Console.Error.WriteLine(e.StackTrace);
            }
        }

        static void RunDemonstration9()
        {
            Console.WriteLine();
            Console.WriteLine("--- Data Mapping Demonstration (C#) (9) ---");

            var measurementData = new Dictionary<string, object>
            {
                { "test_k", 4 },
                { "test_h", null },
                { "pga", 64.56 },
                { "pgb", new List<object> { 43.87, null, null } },
                { "pgd", new List<object> { 67.65, null, 64.356 } },
                { "pgc", 53.4 }
            };

            var parameters = new Dictionary<string, ParameterDefinition>
            {
                { "test_k", new ParameterDefinition { TestId = 38, IsArray = false } },
                { "test_h", new ParameterDefinition { TestId = 41, IsArray = false } },
                { "pga", new ParameterDefinition { TestId = 29, IsArray = false } },
                { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } },
                { "pgd", new ParameterDefinition { TestId = 36, IsArray = true } },
                { "pgc", new ParameterDefinition { TestId = 31, IsArray = false } }
            };

            var relatedParameterArrays = new Dictionary<string, List<string>>
            {
                { "arr5", new List<string> { "pgb", "pgd" } }
            };

            Console.WriteLine("\n[1] Measurement Data:");
            Console.WriteLine(JsonSerializer.Serialize(measurementData, new JsonSerializerOptions { WriteIndented = true }));

            try
            {
                // Map Dict to Flat
                var flatParams = DataMapper.MapDictToFlat(measurementData, parameters);
                Console.WriteLine("\n[2] Mapped to Flat List:");
                Console.WriteLine(JsonSerializer.Serialize(flatParams, new JsonSerializerOptions { WriteIndented = true }));

                // Map Flat to Dict
                var mappedBack = DataMapper.MapFlatToDict(flatParams, parameters, relatedParameterArrays);
                Console.WriteLine("\n[3] Mapped back to Dictionary:");
                Console.WriteLine(JsonSerializer.Serialize(mappedBack, new JsonSerializerOptions { WriteIndented = true }));
            }
            catch (Exception e)
            {
                Console.Error.WriteLine($"\n[Error] {e.Message}");
                Console.Error.WriteLine(e.StackTrace);
            }
            Console.WriteLine("------------------------------------\n");
        }

        static void RunDemonstration10()
        {
            Console.WriteLine();
            Console.WriteLine("--- ROUND Function Demonstration (C#) (10) ---");

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
                { "arr9__0", 2.0m },
                { "arr9__1", 3.0m }
            };

            var formulas = new[]
            {
                "ROUND(44.4446)",
                "ROUND(44.4446, 1)",
                "ROUND([[arr5_c1]])",
                "ROUND([[arr5_c1]], 2)",
                "ROUND([[arr5_c2]], [[arr9]])"
            };

            foreach (var formula in formulas)
            {
                try
                {
                    object result = Formula.EvaluateFormula(formula, parameters);
                    Console.WriteLine($"Formula: {formula}");
                    if (result is System.Collections.IEnumerable list && !(result is string))
                    {
                        var listStr = string.Join(", ", ((System.Collections.IEnumerable)result).Cast<object>());
                        Console.WriteLine($"Result: [{listStr}]");
                    }
                    else
                    {
                        Console.WriteLine($"Result: {result}");
                    }
                    Console.WriteLine();
                }
                catch (Exception e)
                {
                    Console.Error.WriteLine($"Error evaluating '{formula}': {e.Message}");
                }
            }
            Console.WriteLine("------------------------------------\n");
        }
    }
}
