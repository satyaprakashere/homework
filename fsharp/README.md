# F# Learning Project

A structured, fully compilable F# project covering fundamental to advanced functional programming concepts in .NET.

## Overview

This project is built as a compiled .NET console application containing modular, self-contained F# source files. Each module demonstrates practical F# idioms with clear in-code explanations and executable examples.

## Requirements

- [.NET SDK 8.0+](https://dotnet.microsoft.com/) (Tested on .NET 11.0 SDK)

## Project Structure

```text
fsharp/
├── FSharpLearning.fsproj             # .NET F# project configuration & file compilation order
├── Basics.fs                         # Immutability, types, string interpolation, expressions
├── Functions.fs                      # Currying, pipes (|>), composition (>>), tail recursion
├── Collections.fs                    # Lists, arrays, sequences, maps, sets, comprehensions
├── DomainModeling.fs                 # Records, discriminated unions, state machines
├── PatternMatching.fs                # Pattern matching, guards, active patterns
├── UnitsOfMeasure.fs                 # Compile-time dimensional analysis & type safety
├── RailwayOrientedProgramming.fs     # Two-track error handling using Result<'T, 'Error>
├── AsyncAndTasks.fs                  # Async workflows, C# Task interop, concurrency
├── ObjectOriented.fs                 # Classes, interfaces, object expressions, extensions
├── ComputationExpressions.fs         # Custom monadic builders (OptionBuilder)
├── Program.fs                        # CLI runner and entry point
└── README.md                         # Project documentation
```

> [!NOTE]
> In F#, file order inside `FSharpLearning.fsproj` matters strictly. F# enforces top-to-bottom compilation order, preventing circular dependencies by design.

---

## How to Build and Run

### Build the Project
```bash
dotnet build
```

### Run All Modules
```bash
dotnet run
# or
dotnet run -- all
```

### Run Individual Modules
You can run specific learning modules directly by name:

```bash
dotnet run -- basics        # Variables, immutability, strings, expressions
dotnet run -- functions     # Function composition, currying, pipelining
dotnet run -- collections   # Lists, arrays, seq, maps, sets, transformations
dotnet run -- domain        # Records, discriminated unions, domain modeling
dotnet run -- matching      # Pattern matching and active patterns
dotnet run -- units         # Units of measure (m, s, kg, N, mps)
dotnet run -- rop           # Railway Oriented Programming (ROP)
dotnet run -- async         # Async { } workflows and Task { } interop
dotnet run -- oo            # Object-oriented features, classes, interfaces
dotnet run -- monad         # Computation expressions & OptionBuilder
dotnet run -- help          # View command-line help
```

---

## Learning Curriculum

### 1. [Basics.fs](./Basics.fs)
- **Immutability by Default**: Values bound with `let` are immutable.
- **Explicit Mutability**: Mutability requires the `mutable` keyword and `<-` assignment.
- **Type Inference**: Automatic type deduction without sacrificing strong static typing.
- **Expressions vs Statements**: In F#, almost everything is an expression that yields a value (`if ... then ... else ...`).
- **Unit Type `()`**: First-class representation of operations with side effects and no return value.

### 2. [Functions.fs](./Functions.fs)
- **Currying & Partial Application**: Every multi-parameter function is automatically a chain of single-parameter functions.
- **Pipe-Forward (`|>`)**: Eliminates nested parentheses, flowing data naturally from left to right (`data |> transform1 |> transform2`).
- **Function Composition (`>>` / `<<`)**: Combines multiple functions into a new composite function without intermediate arguments.
- **Lambdas**: Anonymous functions defined with `fun x -> ...`.
- **Recursion & Tail Call Optimization**: Tail-recursive functions with accumulators are optimized into fast loops by the compiler.

### 3. [Collections.fs](./Collections.fs)
- **Lists (`'T list`)**: Immutable singly-linked lists with $O(1)$ prepending via `::` (cons).
- **Arrays (`'T[]`)**: Mutable contiguous memory blocks with $O(1)$ indexed access.
- **Sequences (`seq<'T>`)**: Lazy evaluation representing .NET `IEnumerable<'T>`, suitable for infinite streams.
- **Maps & Sets**: Immutable dictionaries and unique collections with set algebra (`union`, `intersect`, `difference`).
- **High-Order Functions**: `List.map`, `List.filter`, `List.fold`, `List.choose`, `List.groupBy`, `List.partition`.

### 4. [DomainModeling.fs](./DomainModeling.fs)
- **Tuples**: Lightweight ad-hoc grouping of heterogeneous values.
- **Records**: Named property bags with automatic structural equality and copy-and-update syntax (`{ user with IsAdmin = true }`).
- **Discriminated Unions (Sum Types)**: Values that can take one of several explicit choices.
- **Single-Case Unions**: Strongly typed IDs (e.g., `CustomerId of int`) that eliminate "primitive obsession".
- **Making Illegal States Unrepresentable**: Modeling domain workflows as state machines so invalid combinations cannot compile.

### 5. [PatternMatching.fs](./PatternMatching.fs)
- **Match Expressions**: Exhaustive pattern deconstruction with compiler warning if a case is missed.
- **When Guards**: Additional condition clauses attached to patterns (`when x > 0`).
- **Multi-Case Active Patterns**: Partitioning an input domain (e.g. `(|Even|Odd|)`, `(|Fizz|Buzz|FizzBuzz|Other|)`).
- **Partial Active Patterns**: Parsing or matching on optional conditions (`(|Integer|_|)`).
- **Type Testing**: Matching on runtime types via `:?`.

### 6. [UnitsOfMeasure.fs](./UnitsOfMeasure.fs)
- **Statically Checked Dimensional Analysis**: Annotating floats and integers with units (`float<m>`, `float<s>`).
- **Derived Units**: Automatic dimension propagation (`m / s` becomes velocity, `kg * m / s^2` becomes Newtons).
- **Zero Runtime Overhead**: Units are erased during compilation, providing high performance with complete type safety.

### 7. [RailwayOrientedProgramming.fs](./RailwayOrientedProgramming.fs)
- **Two-Track Model**: Modeling execution paths as either a Success track or Failure track using `Result<'TSuccess, 'TError>`.
- **`Result.bind`**: Chaining operations that can fail, automatically short-circuiting on the first error.
- **`Result.map`**: Applying normal pure functions to the success track.
- **Kleisli Composition (`>=>`)**: Composing switch functions into end-to-end validation pipelines.

### 8. [AsyncAndTasks.fs](./AsyncAndTasks.fs)
- **`async { ... }` Workflows**: Native F# asynchronous programming with explicit scheduling, cancellation, and `Async.Parallel`.
- **`task { ... }` Interoperability**: Seamless integration with C# Task-based Asynchronous Pattern (TAP) and modern .NET APIs.

### 9. [ObjectOriented.fs](./ObjectOriented.fs)
- **Classes & Constructors**: Object-oriented structures with primary constructors and properties.
- **Interfaces**: Defining and explicitly implementing interfaces (`interface IShape with ...`).
- **Object Expressions**: Instantiating ad-hoc interface implementations without defining classes.
- **Type Extensions**: Adding methods to existing .NET classes (e.g., `System.String`).

### 10. [ComputationExpressions.fs](./ComputationExpressions.fs)
- **Monadic Syntax**: How F# provides syntactical sugar (`let!`, `return`) for complex computation wrappers.
- **Custom `OptionBuilder`**: Implementing `Bind` and `Return` to flatten nested `Some`/`None` checking into clean imperative-looking pipelines.

---

## F# Idioms & Cheat Sheet

| Syntax / Operator | Name | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `let` | Value / Function binding | Declares immutable value or function | `let x = 10` |
| `mutable` | Mutable binding | Declares variable that can be reassigned | `let mutable c = 0; c <- c + 1` |
| `\|>` | Forward pipe | Passes left value as last argument to right function | `5 \|> add 10 \|> double` |
| `>>` | Forward composition | Combines two functions into a new function | `let f = add10 >> double` |
| `::` | Cons operator | Prepends element to an immutable list | `1 :: [2; 3]` |
| `@` | List concatenation | Joins two lists together | `[1; 2] @ [3; 4]` |
| `type DU = A \| B` | Discriminated union | Defines a type with mutually exclusive choices | `type Shape = Circle of float \| Rect of float * float` |
| `{ r with x = y }` | Copy and update | Creates record copy with updated fields | `{ user with IsAdmin = true }` |
| `match ... with` | Pattern matching | Structural deconstruction with exhaustiveness checks | `match opt with Some v -> v \| None -> 0` |
| `[<Measure>]` | Unit of measure | Tag types for physical units | `100.0<m> / 9.58<s>` |
