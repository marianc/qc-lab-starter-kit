# API Documentation

This document provides API documentation for the QC Formula libraries for C#.

## C# API

The C# API provides static methods in the `QCFormula.Formula` class to evaluate QC formulas, extract parameters, and reorder parameters based on dependencies.

### `Formula.EvaluateFormula(string formulaString, Dictionary<string, decimal> parameters) -> object`

Parses and evaluates a QC formula string.

*   **Arguments:**
    *   `formulaString` (string): The formula to evaluate.
    *   `parameters` (Dictionary<string, decimal>): A dictionary of external parameters.
*   **Returns:**
    *   The final result of the evaluation. The result can be a `decimal` or a `List<decimal>`.

**Example:**

```csharp
using QCFormula;

var formula = "v = 3 + [[arr5_c1]] - 2 * [[arr8]]; s = SUM([p1], [p2], [[arr5_c2]], [p3], [[arr8]]); s + v";
var parameters = new Dictionary<string, decimal>
{
    { "p1", 10.0 },
    { "p2", 20.0 },
    { "p3", 15.0 },
    { "arr5_c1__0", 150.0 },
    { "arr5_c1__1", 456.0 },
    { "arr5_c1__2", 656.0 },
    { "arr5_c1__3", 576.0 },
    { "arr5_c2__0", 56.0 },
    { "arr5_c2__1", 897.0 },
    { "arr8__0", 654.0 },
    { "arr8__1", 54.0 },
    { "arr8__2", 567.0 },
    { "arr8__3", 987.0 }
};

var result = (List<decimal>)Formula.EvaluateFormula(formula, parameters);
Console.WriteLine(string.Join(", ", result)); // Output: 2105, 3611, 2785, 1865
```

### `Formula.ExtractParameters(string formulaString) -> List<string>`

Parses a QC formula string and extracts all referenced external parameters.

*   **Arguments:**
    *   `formulaString` (string): The formula to analyze.
*   **Returns:**
    *   A list of unique parameter names referenced in the formula.

**Example:**

```csharp
using QCFormula;

var formula = "a = [p1] + [p2]; s = SUM([[arr7]]); IF(a > 10, s, 0)";
var parameters = Formula.ExtractParameters(formula);
Console.WriteLine(string.Join(", ", parameters)); // Output: arr7__, p1, p2
```

### `Formula.ReorderParametersByDependencies(List<string> parameters, Dictionary<string, List<string>> dependencies) -> List<string>`

Reorders a list of parameters based on their dependencies.

*   **Arguments:**
    *   `parameters` (List<string>): A list of parameter names.
    *   `dependencies` (Dictionary<string, List<string>>): A dictionary where keys are parameter names and values are lists of their dependencies.
*   **Returns:**
    *   A new list of parameter names, reordered according to their dependencies.

**Example:**

```csharp
using QCFormula;

var parameters = new List<string> { "p1", "p2", "p3", "p4" };
var dependencies = new Dictionary<string, List<string>>
{
    { "p1", new List<string> { "p2" } },
    { "p3", new List<string> { "p4" } },
    { "p2", new List<string>() },
    { "p4", new List<string>() }
};

var orderedParameters = Formula.ReorderParametersByDependencies(parameters, dependencies);
Console.WriteLine(string.Join(", ", orderedParameters)); // Output: p2, p1, p4, p3
```

### `Formula.GetUnusedParametersFromDependencies(List<string> parameters, Dictionary<string, List<string>> dependencies, List<string> output) -> List<string>`

Calculates which parameters are "unused" based on a dependency graph and a set of desired output parameters.

An "unused" parameter is one that is not present in the `output` list and is not a direct or indirect dependency of any parameter in the `output` list.

The function also performs validation:
*   It ensures all parameter keys and dependencies exist in the main `parameters` list.
*   It checks for cyclic dependencies.
*   It verifies that all `output` parameters are valid.
An `Exception` is thrown if any of these checks fail.

*   **Arguments:**
    *   `parameters` (List<string>): A list of all available parameter names.
    *   `dependencies` (Dictionary<string, List<string>>): A dictionary where keys are parameter names and values are lists of their dependencies.
    *   `output` (List<string>): A list of the final output parameters that are considered "used".
*   **Returns:**
    *   A list of parameter names that are not used.

**Example:**

```csharp
using QCFormula;

var parameters = new List<string> { "p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8", "p9", "p10", "p11", "p12" };
var dependencies = new Dictionary<string, List<string>>
{
    { "p1", new List<string>() }, { "p2", new List<string>() }, { "p3", new List<string>() },
    { "p4", new List<string> { "p2", "p6", "p11" } },
    { "p5", new List<string> { "p12", "p4", "p8", "p7" } },
    { "p6", new List<string>() }, { "p7", new List<string>() },
    { "p8", new List<string> { "p1", "p2", "p3" } },
    { "p9", new List<string>() }, { "p10", new List<string>() },
    { "p11", new List<string> { "p1", "p2", "p3" } },
    { "p12", new List<string>() }
};
var output = new List<string> { "p4", "p9", "p10" };

var unused = Formula.GetUnusedParametersFromDependencies(parameters, dependencies, output);
Console.WriteLine(string.Join(", ", unused)); // Output: p5, p7, p8, p12
```

### `Formula.GetFormulaReturnType(string formulaString) -> FormulaReturnType`

Parses a QC formula string and detects the return type.

*   **Arguments:**
    *   `formulaString` (string): The formula to analyze.
*   **Returns:**
    *   `FormulaReturnType.Scalar` or `FormulaReturnType.Array`.

**Example:**

```csharp
using QCFormula;

var formulaScalar = "10 + [p1]";
Console.WriteLine(Formula.GetFormulaReturnType(formulaScalar)); // Output: Scalar

var formulaArray = "[[arr1]] + 5";
Console.WriteLine(Formula.GetFormulaReturnType(formulaArray)); // Output: Array
```

### `FormEvaluator`

A static class to evaluate a form containing multiple interdependent formulas.

#### `FormEvaluator.EvaluateForm(Dictionary<string, object> measurementData, Dictionary<string, FormulaInfo> computationData, List<string> orderedParameters, Dictionary<string, List<string>> relatedParameterArrays) -> Dictionary<string, object>`

Evaluates a form based on measurement data and computation rules.

*   **Arguments:**
    *   `measurementData` (Dictionary<string, object>): Dictionary of input values.
    *   `computationData` (Dictionary<string, FormulaInfo>): Dictionary of formula definitions.
    *   `orderedParameters` (List<string>): List of parameter names in evaluation order.
    *   `relatedParameterArrays` (Dictionary<string, List<string>>): Dictionary defining groups of related array parameters.
*   **Returns:**
    *   A dictionary containing the calculated results for the parameters.

#### `FormEvaluator.ConvertFormulasToComputationData(Dictionary<string, string> formulas) -> Dictionary<string, FormulaInfo>`

Converts a dictionary of formula strings into `FormulaInfo` objects.

**Example:**

```csharp
using QCFormula;

var measurementData = new Dictionary<string, object>
{
    { "test_h", 0 },
    { "pga", 65.767 },
    { "pgb", new List<decimal> { 63.4345, 34.8767, 66.423 } }
};

var formulas = new Dictionary<string, string>
{
    { "test_g", "AVG([[pgb]])" },
    { "tlb", "IF([test_h],0,1)" }
};

var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);

var allParams = new List<string>(measurementData.Keys);
allParams.AddRange(computationData.Keys);

var dependencies = new Dictionary<string, List<string>>();
foreach (var k in measurementData.Keys) dependencies[k] = new List<string>();
foreach (var kvp in computationData) dependencies[kvp.Key] = kvp.Value.Dependencies;

var orderedParameters = Formula.ReorderParametersByDependencies(allParams, dependencies);

var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, null);
```

### `DataMapper`

A utility class for mapping between hierarchical measurement data and flat data formats.

#### `DataMapper.MapDictToFlat(Dictionary<string, object> measurementData, Dictionary<string, ParameterDefinition> parameters) -> List<MeasurementFlatData>`

Maps hierarchical dictionary data to a flat list of `MeasurementFlatData`. It performs validation before mapping.

*   **Arguments:**
    *   `measurementData` (Dictionary<string, object>): Dictionary containing measurement values.
    *   `parameters` (Dictionary<string, ParameterDefinition>): Dictionary defining parameters' `TestId` and `IsArray` properties.
*   **Returns:**
    *   A list of `MeasurementFlatData` objects.
*   **Throws:**
    *   `ArgumentException`: If a key in `measurementData` is not defined in `parameters`, or if a value's type (scalar/list) does not match its definition.

#### `DataMapper.MapFlatToDict(List<MeasurementFlatData> flatParams, Dictionary<string, ParameterDefinition> parameters, Dictionary<string, List<string>> relatedParameterArrays) -> Dictionary<string, object>`

Reconstructs hierarchical data from a flat list. It performs validation before mapping.

*   **Arguments:**
    *   `flatParams` (List<MeasurementFlatData>): The flat data list.
    *   `parameters` (Dictionary<string, ParameterDefinition>): Dictionary defining the parameters.
    *   `relatedParameterArrays` (Dictionary<string, List<string>>): Dictionary defining groups of related array parameters to ensure consistent sizing.
*   **Returns:**
    *   A reconstructed hierarchical dictionary.
*   **Throws:**
    *   `ArgumentException`: If a `TestId` in `flatParams` is not defined in `parameters`, or if a parameter in `relatedParameterArrays` is not defined or is not an array.

**Example:**

```csharp
using QCFormula;

var measurementData = new Dictionary<string, object>
{
    { "test_k", 4 },
    { "pgb", new List<object> { 43.87, null, null } }
};

var parameters = new Dictionary<string, ParameterDefinition>
{
    { "test_k", new ParameterDefinition { TestId = 38, IsArray = false } },
    { "pgb", new ParameterDefinition { TestId = 30, IsArray = true } }
};

var relatedParameterArrays = new Dictionary<string, List<string>>
{
    { "arr5", new List<string> { "pgb" } }
};

var flat = DataMapper.MapDictToFlat(measurementData, parameters);
var reconstructed = DataMapper.MapFlatToDict(flat, parameters, relatedParameterArrays);
```

