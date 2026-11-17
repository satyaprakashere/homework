# Zig Learning Cheat Sheet ⚡️

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `zig build-exe main.zig` | Compile to an executable. |
| `zig run main.zig` | Compile and run. |
| `zig test main.zig` | Run tests. |
| `zig build` | Use the build system (build.zig). |

## 🏗 Language Features

### Basic Features
- **Structs**: Data objects with methods: `const User = struct { ... }`.
- **Enums**: Tagged unions with explicit values.
- **Error Unions**: `!T` handles errors without exceptions.
- **Defer**: `defer cleanup()` ensures logic runs at scope exit.
- **Optionals**: `?T` for nullable values.

### Advanced Features
- **[Comptime](file:///Users/prakash/Documents/homework/zig/advanced/comptime_demo.zig)**: Powerful compile-time metaprogramming.
- **Generic Types**: Created using `comptime` functions.
- **Custom Allocators**: Explicit memory management (no hidden allocations).
- **Inline Loops/Ifs**: Unrolled/evaluated at compile-time.
- **Assembly Integration**: Inline assembly for low-level tasks.

## 💡 Quick Tips

### 1. No Hidden Allocations
Zig doesn't allocate memory unless you explicitly pass an allocator.

### 2. Payload Capture
Use `if (opt) |val| { ... }` or `if (res) |val| { ... } else |err| { ... }` to handle optionals and errors.

### 3. Build System
The `build.zig` file is written in Zig itself, providing a powerful way to manage complex builds.
