# QCFormula (C# Implementation)

This directory contains the C# implementation of the Quality Control (QC) Formula engine. It allows for parsing, analyzing, and evaluating mathematical formulas with support for variables, external parameters, arrays, and built-in functions.

This project is part of a .NET monorepo using **Central Package Management (CPM)**. Package versions are managed in `Directory.Packages.props` at the root of the `projects_dotnet` directory.

## Project Structure

The solution consists of three main projects:

*   **QCFormula**: The core class library containing the ANTLR4 parser, visitors, and evaluation logic.
*   **QCFormulaSample**: A console application demonstrating various usage scenarios.
*   **QCFormulaTests**: Unit tests ensuring the correctness of the evaluator and resolver.

## Features

*   **Arithmetic Operations**: `+`, `-`, `*`, `/`, `^`, parentheses.
*   **Comparisons & Logic**: `>`, `>=`, `<`, `<=`, `==`, `!=`, `&&`, `||`.
*   **Data Types**: Supports Scalars (numbers) and Arrays.
*   **Parameters**:
    *   Scalar parameters: `[paramName]`
    *   Array parameters: `[[arrayName]]`
*   **Built-in Functions**:
    *   Math: `SQRT`, `ROUND(value, decimals)`
    *   Logic: `IF(condition, true_val, false_val)`
    *   Aggregates: `SUM`, `COUNT`, `AVG`
    *   Array Manipulation: `FILTER`
*   **Advanced Features**:
    *   Dependency resolution (topological sort of formulas).
    *   Cyclic dependency detection.
    *   Return type inference (`Scalar` vs `Array`).
    *   **Form Evaluator**: Evaluate a collection of interdependent formulas in the correct order.

## Prerequisites

*   .NET SDK (The project is configured for `net10.0` based on the project files).
*   ANTLR4 (Used for generating the parser, though generated files are included).

## getting Started

### Building the Project

Navigate to the `projects_dotnet` directory:

```bash
dotnet build formula_cs/QCFormulaSample.slnx
```

### Running the Sample

To run the demonstration console application:

```bash
dotnet run --project formula_cs/QCFormulaSample/QCFormulaSample.csproj
```

### Running Tests

To execute the unit tests:

```bash
dotnet test formula_cs/QCFormulaTests/QCFormulaTests.csproj
```

## Basic Usage

### 1. Evaluating a Single Formula

```csharp
using QCFormula;
using System.Collections.Generic;

var formula = "10 + [p1] * 2";
var parameters = new Dictionary<string, decimal>
{
    { "p1", 5.0 }
};

// Result is 20.0
var result = Formula.EvaluateFormula(formula, parameters);
```

### 2. Form Evaluation

You can evaluate a dictionary of formulas where some formulas depend on the results of others.

```csharp
using QCFormula;
using System.Collections.Generic;

// 1. Define Measurement Data (Inputs)
var measurementData = new Dictionary<string, object>
{
    { "width", 10.0 },
    { "height", 20.0 },
    { "scaling_factors", new List<decimal> { 1, 2, 3 } } // Array input
};

// 2. Define Formulas
var formulas = new Dictionary<string, string>
{
    { "area", "[width] * [height]" },
    { "scaled_areas", "[[scaling_factors]] * [area]" } // Depends on 'area'
};

// 3. Convert and Prepare
var computationData = FormEvaluator.ConvertFormulasToComputationData(formulas);

var allParams = new List<string>(measurementData.Keys);
allParams.AddRange(computationData.Keys);

var dependencies = new Dictionary<string, List<string>>();
foreach (var k in measurementData.Keys) dependencies[k] = new List<string>();
foreach (var kvp in computationData) dependencies[kvp.Key] = kvp.Value.Dependencies;

// 4. Calculate Order
var orderedParameters = Formula.ReorderParametersByDependencies(allParams, dependencies);

// 5. Evaluate
var results = FormEvaluator.EvaluateForm(measurementData, computationData, orderedParameters, null);

// results["area"] will be 200.0
// results["scaled_areas"] will be [200.0, 400.0, 600.0]
```

### 3. Parameter Extraction

Identify which parameters are required by a formula string.

```csharp
var formula = "[p1] + SUM([[arr1]])";
var params = Formula.ExtractParameters(formula);
// Output: "p1", "arr1__" (Note: array parameters currently return with suffix in raw extraction)
```

## ANTLR Generation

If you modify the grammar file (`./Grammar/QCFormula.g4`), you need to regenerate the C# lexer and parser.

```bash
java -jar path/to/antlr-4.13.1-complete.jar -Dlanguage=CSharp -visitor -o QCFormula/ANTLRGenerated ./Grammar/QCFormula.g4
```
