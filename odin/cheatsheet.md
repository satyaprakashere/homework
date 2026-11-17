# Odin Learning Cheat Sheet 🛡️

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `odin run .` | Build and run. |
| `odin build .` | Build executable. |
| `odin test .` | Run tests. |

## 🏗 Advanced Concepts

- **[Procedures](file:///Users/prakash/Documents/homework/odin/advanced/procedures.odin)**: Multiple return values and procedure overloading.

## 💡 Quick Tips

### 1. Explicit Memory
Use `defer delete(slice)` for cleanups.

### 2. Slices
`s := data[1:5]` - A view into an array.

### 3. Context
The `context` variable is implicit and carries allocators and loggers.
