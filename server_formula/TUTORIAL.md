
# QC Formula Tutorial

Welcome to the QC Formula tutorial! This guide will walk you through the syntax of the QC Formula language, from basic operations to more advanced features.

## Introduction

The QC Formula language is a simple scripting language designed for evaluating quality control formulas. It allows you to perform calculations, use variables, and access external data through parameters.

## Basic Syntax

### Comments

Comments are used to add notes to your formula and are ignored by the evaluator. Single-line comments start with `//`.

```
// This is a comment
```

### Variables

Variables are used to store values. You can assign a value to a variable using the `=` operator. Each statement must end with a semicolon `;`.

```
a = 10; // Assign the value 10 to variable 'a'
b = a + 5; // Use the value of 'a' in another calculation
```

### Final Expression

A QC formula script consists of zero or more statements and a final expression. The final expression is the result of the evaluation. It does not need to be terminated by a semicolon.

```
a = 10;
b = 20;
a + b // The result of the evaluation will be 30
```

## Parameters

Parameters allow you to pass external data into your formula. There are two types of parameters: scalar and array.

### Scalar Parameters

Scalar parameters represent a single value. They are referenced using square brackets `[]`.

```
[p1] + [p2]
```

In this example, `p1` and `p2` are scalar parameters that must be provided when evaluating the formula.

### Array Parameters

Array parameters represent a list of values. They are referenced using decimal square brackets `[[]]`.

```
SUM([[arr1]])
```

In this example, `arr1` is an array parameter. Array parameters are typically used with aggregate functions like `SUM`, `COUNT`, and `AVG`.

## Expressions and Operators

### Arithmetic Operators

The following arithmetic operators are supported:

| Operator | Description      |
| :---     | :---             |
| `+`      | Addition         |
| `-`      | Subtraction      |
| `*`      | Multiplication   |
| `/`      | Division         |
| `^`      | Power            |

```
(5 + 2) * 3^2 / 2
```

### Comparison Operators

The following comparison operators are supported:

| Operator | Description      |
| :---     | :---             |
| `>`      | Greater than     |
| `>=`     | Greater than or equal to |
| `<`      | Less than        |
| `<=`     | Less than or equal to |
| `==`     | Equal to         |
| `!=`     | Not equal to     |

### Logical Operators

The following logical operators are supported:

| Operator | Description      |
| :---     | :---             |
| `&&`     | Logical AND      |
| `||`     | Logical OR       |

```
([p1] > 10) && ([p2] < 20)
```

## Functions

The QC Formula language provides several built-in functions.

### `SQRT(expression)`

Returns the square root of a number.

```
SQRT(16) // Returns 4
```

### `ROUND(value, decimals)`

Rounds a numeric value to a specified number of decimal places.

```
ROUND(12.3456, 2) // Returns 12.35
```

### `SUM(arg1, arg2, ...)`

Returns the sum of a list of numbers. Arguments can be expressions, scalar parameters, or array parameters.

```
SUM([p1], [p2], [[arr1]], 5) 
```

### `COUNT(arg1, arg2, ...)`

Returns the count of all numbers in the arguments. Arguments can be expressions, scalar parameters, or array parameters.

```
COUNT([[arr1]], [[arr2]])
```

### `AVG(arg1, arg2, ...)`

Returns the average of a list of numbers. Arguments can be expressions, scalar parameters, or array parameters.

```
AVG([[arr1]], [p1])
```

### `IF(condition, value_if_true, value_if_false)`

Evaluates a condition and returns one of two values.

```
IF([p1] > 10, 1, 0) // Returns 1 if p1 is greater than 10, otherwise 0
```

### `FILTER(condition_array, data_array)`

Filters an array based on a condition array. The `condition_array` must be an array of booleans (0 or 1), and the `data_array` can be an array of numbers. The function returns a new array containing only the items from `data_array` where the corresponding value in `condition_array` is true (1).

```
// If arr1 is [1, 0, 1, 0] and arr2 is [10, 20, 30, 40],
// this will return [10, 30]
FILTER([[arr1]], [[arr2]]) 
```

## Array Expressions

A powerful feature of the QC Formula language is the ability to perform calculations with arrays. When an arithmetic operation is performed between a scalar (a single number) and an array, the operation is applied to each element of the array, resulting in a new array.

```
3 + [[arr1]] // If arr1 is [1, 2, 3], the result is [4, 5, 6]
```

When an operation is performed between two arrays of the same size, the operation is performed element-wise.

```
[[arr1]] + [[arr2]] // If arr1 is [1, 2] and arr2 is [3, 4], the result is [4, 6]
```

If you perform an operation between two arrays of different sizes, the evaluator will throw an error.

### Array Comparisons and Logical Operations

Comparison and logical operators can also be used with arrays. When you use a comparison operator between an array and a scalar, it returns a boolean array (an array of 0s and 1s).

```
// If arr1 is [1, 5, 10], this will return [0, 0, 1]
[[arr1]] > 5 
```

You can use these boolean arrays to perform logical operations or to filter other arrays.

```
// If arr1 is [1, 5, 10] and arr2 is [2, 6, 8],
// this will return [0, 0, 0]
([[arr1]] > 5) && ([[arr2]] < 5)
```

Here is an example of how to use a boolean array with the `FILTER` function:

```
// If arr1 is [1, 5, 10, 15], this will return [10, 15]
FILTER([[arr1]] > 5, [[arr1]])
```

## Putting It All Together

Here is a more complex example that demonstrates the use of variables, functions, and array expressions:

```
// This formula calculates a value 'v' based on array expressions,
// then calculates a sum 's' using aggregate functions, and finally,
// adds the scalar 's' to each element of the array 'v'.

v = 3 + [[arr5_c1]] - 2 * [[arr8]];
s = SUM([p1], [p2], [[arr5_c2]], [p3], [[arr8]]);
s + v
```

Let's break down this example:

1.  **`v = 3 + [[arr5_c1]] - 2 * [[arr8]]`**
    *   `[[arr5_c1]]` and `[[arr8]]` are array parameters. They must have the same number of elements.
    *   `3 + [[arr5_c1]]`: The scalar value `3` is added to each element of the `[[arr5_c1]]` array.
    *   `2 * [[arr8]]`: The scalar value `2` is multiplied by each element of the `[[arr8]]` array.
    *   The resulting arrays from the two operations are then subtracted element-wise.

2.  **`s = SUM([p1], [p2], [[arr5_c2]], [p3], [[arr8]])`**
    *   The `SUM` function calculates the sum of all the provided arguments. It flattens any array parameters into a single list of numbers before summing them up.

3.  **`s + v`**
    *   The final expression adds the scalar value `s` to each element of the array `v`, resulting in a new array.
