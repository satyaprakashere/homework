# Elixir Learning Cheat Sheet 💧

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `iex` | Start interactive Elixir shell. |
| `mix new <name>` | Create a new Mix project. |
| `mix run` | Run the project. |
| `mix test` | Run tests. |

## 🏗 Language Features

### Basic Features
- **Modules & Functions**: Logic grouped into modules: `defmodule ... do def ... end`.
- **Pattern Matching**: Destructure and match with `=`: `{a, b} = {1, 2}`.
- **Pipe Operator**: Chain functions: `data |> f1() |> f2()`.
- **Recursion**: Looping via function calls (Tail Call Optimization).
- **Lists & Maps**: Linked lists `[1, 2]` and key-value maps `%{a: 1}`.

### Advanced Features
- **[GenServer](file:///Users/prakash/Documents/homework/elixir/advanced/worker.ex)**: Generic server behavior for stateful processes.
- **Supervisors**: Managing process lifecycles and recovery.
- **OTP (Open Telecom Platform)**: The framework for building fault-tolerant systems.
- **Macros**: Compile-time code generation: `quote` and `unquote`.
- **Concurrency**: Lightweight processes (actors) with `spawn`, `send`, `receive`.

## 💡 Quick Tips

### 1. Fault Tolerance
"Let it crash" philosophy—use supervisors to restart failed processes.

### 2. Immutability
All data is immutable. Transformations return new copies of the data.

### 3. Documentation
Use `@doc` for function documentation and `h` in IEx to read it.
