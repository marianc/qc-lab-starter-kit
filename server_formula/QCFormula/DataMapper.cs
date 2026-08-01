using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace QCFormula
{
    public class ParameterDefinition
    {
        public long TestId { get; set; }
        public bool IsArray { get; set; }
    }

    public class MeasurementFlatData
    {
        public long TestId { get; set; }
        public int Idx { get; set; }
        public decimal Value { get; set; }
        public decimal? ConditionValue { get; set; }
    }

    public static class DataMapper
    {
        public static List<MeasurementFlatData> MapDictToFlat(
            Dictionary<string, object> measurementData,
            Dictionary<string, ParameterDefinition> parameters)
        {
            ValidateMapDictToFlat(measurementData, parameters);

            var result = new List<MeasurementFlatData>();

            foreach (var kvp in measurementData)
            {
                if (kvp.Value == null) continue;
                if (!parameters.TryGetValue(kvp.Key, out var paramDef)) continue;

                if (paramDef.IsArray)
                {
                    var list = AsDecimalList(kvp.Value);
                    if (list == null) continue;

                    for (int i = 0; i < list.Count; i++)
                    {
                        if (list[i].HasValue)
                        {
                            result.Add(new MeasurementFlatData
                            {
                                TestId = paramDef.TestId,
                                Idx = i,
                                Value = list[i].Value
                            });
                        }
                    }
                }
                else
                {
                    var val = AsDecimal(kvp.Value);
                    if (val.HasValue)
                    {
                        result.Add(new MeasurementFlatData
                        {
                            TestId = paramDef.TestId,
                            Idx = 0,
                            Value = val.Value
                        });
                    }
                }
            }

            return result;
        }

        public static void ValidateMapDictToFlat(
            Dictionary<string, object> measurementData,
            Dictionary<string, ParameterDefinition> parameters)
        {
            // 1. All 'measurementData' dictionary keys must be present as keys in dictionary 'parameters'
            foreach (var key in measurementData.Keys)
            {
                if (!parameters.ContainsKey(key))
                {
                    throw new ArgumentException($"Measurement data key '{key}' is not defined in parameters.");
                }
            }

            // 2. Check types
            foreach (var kvp in measurementData)
            {
                if (kvp.Value == null) continue;
                
                var paramDef = parameters[kvp.Key];
                if (paramDef.IsArray)
                {
                    if (!IsList(kvp.Value))
                    {
                         throw new ArgumentException($"Parameter '{kvp.Key}' is expected to be an array (List).");
                    }
                }
                else
                {
                    if (AsDecimal(kvp.Value) == null && kvp.Value != null)
                    {
                         if (IsList(kvp.Value))
                         {
                             throw new ArgumentException($"Parameter '{kvp.Key}' is expected to be a scalar (decimal), but found a list.");
                         }
                    }
                }
            }
        }

        public static Dictionary<string, object> MapFlatToDict(
            List<MeasurementFlatData> flatParams,
            Dictionary<string, ParameterDefinition> parameters,
            Dictionary<string, List<string>> relatedParameterArrays)
        {
            ValidateMapFlatToDict(flatParams, parameters, relatedParameterArrays);

            var result = new Dictionary<string, object>();
            var groupedFlat = flatParams.GroupBy(p => p.TestId).ToDictionary(g => g.Key, g => g.ToList());

            // We iterate over 'parameters' to reconstruct the dictionary
            foreach (var kvp in parameters)
            {
                var paramCode = kvp.Key;
                var paramDef = kvp.Value;

                if (paramDef.IsArray)
                {
                    int maxIdx = -1;
                    
                    // Check if part of related arrays to determine size
                    string relatedGroupKey = null;
                    if (relatedParameterArrays != null)
                    {
                        foreach (var rKvp in relatedParameterArrays)
                        {
                            if (rKvp.Value.Contains(paramCode))
                            {
                                relatedGroupKey = rKvp.Key;
                                break;
                            }
                        }
                    }

                    if (relatedGroupKey != null)
                    {
                        // Find max index across all related parameters
                        var relatedCodes = relatedParameterArrays[relatedGroupKey];
                        foreach (var relatedCode in relatedCodes)
                        {
                            if (parameters.TryGetValue(relatedCode, out var relParamDef))
                            {
                                if (groupedFlat.TryGetValue(relParamDef.TestId, out var grp))
                                {
                                    int m = grp.Any() ? grp.Max(x => x.Idx) : -1;
                                    if (m > maxIdx) maxIdx = m;
                                }
                            }
                        }
                    }
                    else
                    {
                        // Just this parameter
                        if (groupedFlat.TryGetValue(paramDef.TestId, out var grp))
                        {
                            maxIdx = grp.Any() ? grp.Max(x => x.Idx) : -1;
                        }
                    }

                    // Reconstruct list
                    if (maxIdx == -1 && !groupedFlat.ContainsKey(paramDef.TestId))
                    {
                         result[paramCode] = new List<decimal?>();
                         continue;
                    }
                    
                    if (maxIdx > -1)
                    {
                         var list = new List<decimal?>();
                         // Initialize with nulls
                         for(int i=0; i<=maxIdx; i++) list.Add(null);

                         if (groupedFlat.TryGetValue(paramDef.TestId, out var values))
                         {
                             foreach (var v in values)
                             {
                                 if (v.Idx <= maxIdx)
                                 {
                                     list[v.Idx] = v.Value;
                                 }
                             }
                         }
                         result[paramCode] = list;
                    }
                    else
                    {
                        result[paramCode] = new List<decimal?>();
                    }
                }
                else
                {
                    // Scalar
                    if (groupedFlat.TryGetValue(paramDef.TestId, out var values))
                    {
                        var val = values.FirstOrDefault(v => v.Idx == 0);
                        result[paramCode] = val?.Value;
                    }
                    else
                    {
                        result[paramCode] = null;
                    }
                }
            }

            return result;
        }

        public static void ValidateMapFlatToDict(
            List<MeasurementFlatData> flatParams,
            Dictionary<string, ParameterDefinition> parameters,
            Dictionary<string, List<string>> relatedParameterArrays)
        {
            // 1. Check 'flatParams', if all TestId are also present in 'parameters'
            var validTestIds = new HashSet<long>(parameters.Values.Select(p => p.TestId));
            foreach (var item in flatParams)
            {
                if (!validTestIds.Contains(item.TestId))
                {
                     throw new ArgumentException($"TestId '{item.TestId}' found in flat parameters is not defined in parameters.");
                }
            }

            // 2. Check 'relatedParameterArrays'
            if (relatedParameterArrays != null)
            {
                foreach (var group in relatedParameterArrays)
                {
                    foreach (var paramName in group.Value)
                    {
                        if (!parameters.TryGetValue(paramName, out var paramDef))
                        {
                             throw new ArgumentException($"Related array parameter '{paramName}' is not defined in parameters.");
                        }
                        
                        if (!paramDef.IsArray)
                        {
                            throw new ArgumentException($"Related parameter '{paramName}' must be defined as an array (IsArray=true).");
                        }
                    }
                }
            }
        }

        // Helpers
        private static bool IsList(object o)
        {
            if (o == null) return false;
            if (o is JsonElement je) return je.ValueKind == JsonValueKind.Array;
            // string is IEnumerable but we don't want to treat it as list of numbers
            return o is System.Collections.IEnumerable && !(o is string);
        }

        private static List<decimal?> AsDecimalList(object o)
        {
            if (o == null) return null;
            var list = new List<decimal?>();
            if (o is JsonElement je && je.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in je.EnumerateArray())
                {
                    list.Add(AsDecimal(item));
                }
                return list;
            }
            if (o is System.Collections.IEnumerable enumerable)
            {
                foreach (var item in enumerable)
                {
                    list.Add(AsDecimal(item));
                }
                return list;
            }
            return null;
        }

        private static decimal? AsDecimal(object o)
        {
            if (o == null) return null;
            if (o is decimal d) return d;
            if (o is int i) return (decimal)i;
            if (o is float f) return (decimal)f;
            if (o is decimal dec) return (decimal)dec;
            if (o is long l) return (decimal)l;
            if (o is byte b) return (decimal)b;
            if (o is short s) return (decimal)s;
            
            if (o is JsonElement je)
            {
                if (je.ValueKind == JsonValueKind.Number) return je.GetDecimal();
                if (je.ValueKind == JsonValueKind.String && decimal.TryParse(je.GetString(), System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out decimal ds)) return ds;
                if (je.ValueKind == JsonValueKind.True) return 1m;
                if (je.ValueKind == JsonValueKind.False) return 0m;
                if (je.ValueKind == JsonValueKind.Null) return null;
                return null;
            }

            try
            {
                return Convert.ToDecimal(o, System.Globalization.CultureInfo.InvariantCulture);
            }
            catch
            {
                return null;
            }
        }
    }
}