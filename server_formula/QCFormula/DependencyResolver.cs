using System;
using System.Collections.Generic;
using System.Linq;

namespace QCFormula
{
    public static class DependencyResolver
    {
        public static bool FindCyclicDependencies(Dictionary<string, List<string>> dependencies)
        {
            var visited = new HashSet<string>();
            var path = new HashSet<string>();

            foreach (var node in dependencies.Keys)
            {
                if (!visited.Contains(node))
                {
                    if (FindCyclicDependenciesUtil(node, dependencies, visited, path))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        private static bool FindCyclicDependenciesUtil(string node, Dictionary<string, List<string>> dependencies, HashSet<string> visited, HashSet<string> path)
        {
            visited.Add(node);
            path.Add(node);

            if (dependencies.TryGetValue(node, out var neighbors))
            {
                foreach (var neighbor in neighbors)
                {
                    if (!visited.Contains(neighbor))
                    {
                        if (FindCyclicDependenciesUtil(neighbor, dependencies, visited, path))
                        {
                            return true;
                        }
                    }
                    else if (path.Contains(neighbor))
                    {
                        return true;
                    }
                }
            }

            path.Remove(node);
            return false;
        }

        public static List<string> ReorderParameters(List<string> parameters, Dictionary<string, List<string>> dependencies)
        {
            foreach (var kvp in dependencies)
            {
                foreach (var dep in kvp.Value)
                {
                    if (!parameters.Contains(dep))
                    {
                        throw new Exception($"Unknown dependency '{dep}' for parameter '{kvp.Key}'.");
                    }
                }
            }

            if (FindCyclicDependencies(dependencies))
            {
                throw new Exception("Cyclic dependency detected.");
            }

            var independentParams = parameters.Where(p => !dependencies.ContainsKey(p) || dependencies[p] == null || dependencies[p].Count == 0).ToList();
            var dependentParams = parameters.Where(p => dependencies.ContainsKey(p) && dependencies[p] != null && dependencies[p].Count > 0).ToList();

            var orderedParameters = new List<string>(independentParams);

            while (dependentParams.Count > 0)
            {
                bool placedInPass = false;
                var placements = new List<(int index, string param)>();

                foreach (var param in dependentParams)
                {
                    var deps = dependencies.ContainsKey(param) ? dependencies[param] : new List<string>();
                    
                    if (deps.All(orderedParameters.Contains))
                    {
                        int lastDepIndex = -1;
                        foreach (var dep in deps)
                        {
                            int index = orderedParameters.IndexOf(dep);
                            if (index > lastDepIndex)
                            {
                                lastDepIndex = index;
                            }
                        }
                        placements.Add((lastDepIndex + 1, param));
                    }
                }

                if (placements.Count > 0)
                {
                    // Sort placements to ensure deterministic order and correct insertion
                    // Sort logic from TS: a.index - b.index, then original param index
                    placements.Sort((a, b) =>
                    {
                        if (a.index != b.index) return a.index.CompareTo(b.index);
                        return parameters.IndexOf(a.param).CompareTo(parameters.IndexOf(b.param));
                    });

                    int offset = 0;
                    foreach (var placement in placements)
                    {
                        orderedParameters.Insert(placement.index + offset, placement.param);
                        dependentParams.Remove(placement.param);
                        offset++;
                    }
                    placedInPass = true;
                }

                if (!placedInPass && dependentParams.Count > 0)
                {
                    throw new Exception($"Could not resolve dependencies for: {string.Join(", ", dependentParams)}");
                }
            }

            return orderedParameters;
        }

        public static List<string> GetUnusedParameters(List<string> parameters, Dictionary<string, List<string>> dependencies, List<string> output)
        {
            var allParams = new HashSet<string>(parameters);

            // Validation 1: Check for unknown dependencies
            foreach (var kvp in dependencies)
            {
                if (!allParams.Contains(kvp.Key))
                {
                    throw new Exception($"Unknown parameter '{kvp.Key}' in dependencies keys.");
                }
                foreach (var dep in kvp.Value)
                {
                    if (!allParams.Contains(dep))
                    {
                        throw new Exception($"Unknown dependency '{dep}' for parameter '{kvp.Key}'.");
                    }
                }
            }

            // Validation 2: Check for valid output parameters
            foreach (var param in output)
            {
                if (!allParams.Contains(param))
                {
                    throw new Exception($"Output parameter '{param}' not found in parameters list.");
                }
            }

            // Validation 3: Check for cyclic dependencies
            if (FindCyclicDependencies(dependencies))
            {
                throw new Exception("Cyclic dependency detected.");
            }

            // Core Logic: Find all used parameters
            var used = new HashSet<string>();
            var toProcess = new Queue<string>(output);

            while (toProcess.Count > 0)
            {
                var param = toProcess.Dequeue();
                if (!used.Contains(param))
                {
                    used.Add(param);
                    if (dependencies.TryGetValue(param, out var deps))
                    {
                        foreach (var dep in deps)
                        {
                            toProcess.Enqueue(dep);
                        }
                    }
                }
            }

            return parameters.Where(p => !used.Contains(p)).ToList();
        }
    }
}
