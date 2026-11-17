# Erlang Learning Cheat Sheet 📞

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `erlc main.erl` | Compile a module. |
| `erl` | Start Erlang shell. |
| `rebar3 build` | Build with Rebar3. |

## 🏗 Advanced Concepts

- **[Concurrency](file:///Users/prakash/Documents/homework/erlang/advanced/concurrency.erl)**: Processes and message passing.

## 💡 Quick Tips

### 1. Atoms
Constants that start with lowercase: `ok`, `error`, `my_atom`.

### 2. Pattern Matching
`{ok, Value} = some_func()` - Direct extraction.

### 3. Fault Tolerance
"Let it crash" philosophy - supervised processes.
