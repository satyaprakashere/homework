# Julia Learning Cheat Sheet 🍕

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `julia main.jl` | Run a script. |
| `julia` | Start REPL. |
| `Pkg.add("Package")` | Install a package. |

## 🏗 Advanced Concepts

- **[Multiple Dispatch](file:///Users/prakash/Documents/homework/julia/advanced/multiple_dispatch.jl)**: Dynamic dispatch based on all argument types.

## 💡 Quick Tips

### 1. Vectorization
`a .+ b` - The dot operator vectorizes any function.

### 2. Performance
Avoid global variables; use functions for type stability.

### 3. JIT Compilation
The first run is slow (compilation), subsequent runs are fast.
