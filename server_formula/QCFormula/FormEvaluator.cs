using System;
using System.Collections.Generic;
using System.Linq;

namespace QCFormula
{
    public static class FormEvaluator
    {
        public static Dictionary<string, object> EvaluateForm(
            Dictionary<string, object> measurementData,
            Dictionary<string, FormulaInfo> computationData,
            List<string> orderedParameters,
            Dictionary<string, List<string>> relatedParameterArrays)
        {
            ValidateInputArguments(measurementData, computationData, orderedParameters, relatedParameterArrays);

            var currentData = new Dictionary<string, object>(measurementData);
            var finalResults = new Dictionary<string, object>();

            foreach (var paramName in orderedParameters)
            {
                if (computationData.ContainsKey(paramName))
                {
                    var info = computationData[paramName];
                    object result = null;

                    if (ValidateFormulaArguments(info, currentData, relatedParameterArrays))
                    {
                        try
                        {
                            // Prepare arguments for this specific formula
                            // We only need dependencies
                            var formulaArgs = new Dictionary<string, object>();
                            foreach (var dep in info.Dependencies)
                            {
                                if (currentData.ContainsKey(dep))
                                {
                                    formulaArgs[dep] = currentData[dep];
                                }
                            }

                            var flatArgs = ToFlatMap(formulaArgs);
                            result = Formula.EvaluateFormula(info.Formula, flatArgs);
                        }
                        catch
                        {
                            // On error, return null/empty based on return type
                            result = GetDefaultValue(info.ReturnType);
                        }
                    }
                    else
                    {
                        result = GetDefaultValue(info.ReturnType);
                    }
                    
                    currentData[paramName] = result;
                    finalResults[paramName] = result;
                }
            }

            return finalResults;
        }

        private static object GetDefaultValue(FormulaReturnType type)
        {
            return type == FormulaReturnType.Array ? new List<decimal>() : null;
        }

        public static void ValidateInputArguments(
            Dictionary<string, object> measurementData,
            Dictionary<string, FormulaInfo> computationData,
            List<string> orderedParameters,
            Dictionary<string, List<string>> relatedParameterArrays)
        {
            // 1. measurementData keys different from computationData keys
            var measureKeys = new HashSet<string>(measurementData.Keys);
            var compKeys = new HashSet<string>(computationData.Keys);

            if (measureKeys.Overlaps(compKeys))
            {
                var overlap = string.Join(", ", measureKeys.Intersect(compKeys));
                throw new ArgumentException($"Measurement data and Computation data keys must be disjoint. Overlapping keys: {overlap}");
            }

            // 2. Union of keys equals orderedParameters (ignoring order)
            var unionKeys = new HashSet<string>(measureKeys);
            unionKeys.UnionWith(compKeys);
            var orderedSet = new HashSet<string>(orderedParameters);

            if (!unionKeys.SetEquals(orderedSet))
            {
                throw new ArgumentException("The union of Measurement and Computation keys must match orderedParameters elements.");
            }

            // 3. relatedParameterArrays check
            if (relatedParameterArrays != null)
            {
                foreach (var kvp in relatedParameterArrays)
                {
                    foreach (var paramName in kvp.Value)
                    {
                        if (!measureKeys.Contains(paramName))
                        {
                             throw new ArgumentException($"Related array parameter '{paramName}' in group '{kvp.Key}' is not present in measurementData.");
                        }
                        
                        var val = measurementData[paramName];
                        if (!(val is List<decimal> || val is List<decimal?>))
                        {
                             // Note: Input might be List<decimal> or List<decimal?> or even object[] depending on deserialization.
                             // The prompt says "array of nullable numeric".
                             // We'll check if it can be treated as a list.
                             if (!IsList(val))
                             {
                                 throw new ArgumentException($"Related parameter '{paramName}' must be an array.");
                             }
                        }
                    }
                }
            }
        }

        public static bool ValidateFormulaArguments(
            FormulaInfo formulaInfo,
            Dictionary<string, object> currentData,
            Dictionary<string, List<string>> relatedParameterArrays)
        {
            // Check each dependency
            foreach (var dep in formulaInfo.Dependencies)
            {
                if (!currentData.TryGetValue(dep, out var val))
                {
                    return false; // Dependency missing
                }

                if (IsList(val))
                {
                    var list = AsDecimalList(val);
                    if (list == null || list.Count == 0) return false; // Empty or null list
                    if (list.Any(x => x == null)) return false; // Contains null values
                }
                else
                {
                    if (val == null) return false; // Scalar null
                }
            }

            // Check related arrays size
            // We need to find if any dependencies belong to the same related group
            if (relatedParameterArrays != null)
            {
                foreach (var group in relatedParameterArrays.Values)
                {
                    var relatedDeps = group.Intersect(formulaInfo.Dependencies).ToList();
                    if (relatedDeps.Count > 1)
                    {
                        // Check sizes
                        int? expectedSize = null;
                        foreach (var dep in relatedDeps)
                        {
                            if (currentData.TryGetValue(dep, out var val) && IsList(val))
                            {
                                var list = AsDecimalList(val);
                                // We already checked for null/empty above, but decimal check size
                                if (list == null) return false;
                                
                                if (expectedSize == null)
                                {
                                    expectedSize = list.Count;
                                }
                                else
                                {
                                    if (list.Count != expectedSize) return false; // Size mismatch
                                }
                            }
                        }
                    }
                }
            }

            return true;
        }

        public static Dictionary<string, decimal> ToFlatMap(Dictionary<string, object> data)
        {
            var flat = new Dictionary<string, decimal>();
            foreach (var kvp in data)
            {
                if (kvp.Value == null) continue;

                if (IsList(kvp.Value))
                {
                    var list = AsDecimalList(kvp.Value);
                    if (list != null)
                    {
                        for (int i = 0; i < list.Count; i++)
                        {
                            if (list[i].HasValue)
                            {
                                flat[$"{kvp.Key}__{i}"] = list[i].Value;
                            }
                        }
                    }
                }
                else
                {
                    decimal? d = AsDecimal(kvp.Value);
                    if (d.HasValue)
                    {
                        flat[kvp.Key] = d.Value;
                    }
                }
            }
            return flat;
        }

        public static Dictionary<string, object> FromFlatMap(Dictionary<string, decimal> flatMap)
        {
            var result = new Dictionary<string, object>();
            var arrayBuffer = new Dictionary<string, SortedDictionary<int, decimal>>();

            foreach (var kvp in flatMap)
            {
                if (kvp.Key.Contains("__"))
                {
                    var parts = kvp.Key.Split(new[] { "__" }, StringSplitOptions.RemoveEmptyEntries);
                    if (parts.Length == 2 && int.TryParse(parts[1], out int index))
                    {
                        var name = parts[0];
                        if (!arrayBuffer.ContainsKey(name))
                        {
                            arrayBuffer[name] = new SortedDictionary<int, decimal>();
                        }
                        arrayBuffer[name][index] = kvp.Value;
                    }
                    else
                    {
                        // Fallback for weird keys? Treat as scalar?
                        result[kvp.Key] = kvp.Value;
                    }
                }
                else
                {
                    result[kvp.Key] = kvp.Value;
                }
            }

            // Reconstruct arrays
            foreach (var kvp in arrayBuffer)
            {
                // We assume the array is dense for reconstruction or at least we return list of doubles
                // User requirement: "convert back and forth". 
                // If we have indices 0, 1, 3. We'll produce a list of size 4 with index 2 as null?
                // The output of EvaluateFormula is usually just List<decimal> (dense).
                // But FromFlatMap is general. 
                // Let's create a dense list up to max index.
                int maxIndex = kvp.Value.Keys.Max();
                var list = new List<decimal?>();
                for (int i = 0; i <= maxIndex; i++)
                {
                    if (kvp.Value.ContainsKey(i))
                    {
                        list.Add(kvp.Value[i]);
                    }
                    else
                    {
                        list.Add(null);
                    }
                }
                // Convert to List<decimal> if no nulls? Or keep as List<decimal?>?
                // The signature says returns Dictionary<string, object>.
                // Existing EvaluateFormula returns List<decimal> (non-nullable).
                // But here we might have nulls if we reconstruct from sparse flat map.
                // We'll return List<decimal?>.
                result[kvp.Key] = list;
            }

            return result;
        }

        public static Dictionary<string, FormulaInfo> ConvertFormulasToComputationData(Dictionary<string, string> formulas)
        {
            var result = new Dictionary<string, FormulaInfo>();
            foreach (var kvp in formulas)
            {
                var rawDeps = Formula.ExtractParameters(kvp.Value);
                var deps = rawDeps.Select(d => d.EndsWith("__") ? d.Substring(0, d.Length - 2) : d).ToList();

                result[kvp.Key] = new FormulaInfo
                {
                    Formula = kvp.Value,
                    Dependencies = deps,
                    ReturnType = Formula.GetFormulaReturnType(kvp.Value)
                };
            }
            return result;
        }

        // Helpers for type checking and conversion
        private static bool IsList(object o)
        {
            if (o == null) return false;
            return o is System.Collections.IEnumerable && !(o is string);
        }

        private static List<decimal?> AsDecimalList(object o)
        {
            if (o == null) return null;
            var list = new List<decimal?>();
            foreach (var item in (System.Collections.IEnumerable)o)
            {
                list.Add(AsDecimal(item));
            }
            return list;
        }

        private static decimal? AsDecimal(object o)
        {
            if (o == null) return null;
            if (o is decimal d) return d;
            if (o is int i) return (decimal)i;
            if (o is float f) return (decimal)f;
            if (o is decimal dec) return (decimal)dec;
            try
            {
                return Convert.ToDecimal(o);
            }
            catch
            {
                return null;
            }
        }
    }
}
