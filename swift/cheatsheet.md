# Swift Learning Cheat Sheet 🍎

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `swift run` | Build and run a package. |
| `swift build` | Build the package. |
| `swift test` | Run tests. |
| `xcodebuild` | Build from command line (macOS). |

## 🏗 Language Features

### Basic Features
- **Strong Typing & Inference**: Swift is type-safe and infers types.
- **Optionals**: Explicitly handle missing values: `var name: String?`.
- **Control Flow**: `if let`, `guard let`, and powerful `switch` statements.
- **Classes vs Structs**: Structs (Value type) are preferred; Classes (Reference type) for inheritance.
- **Enums**: Can have raw values and associated values.

### Advanced Features
- **[Concurrency](./advanced/Concurrency.swift)**: Modern `async/await` and `Task` groups.
- **Protocols**: Define blueprints of methods (Protocol Oriented Programming).
- **Generics**: Reusable, type-safe functions and types.
- **Extensions**: Add functionality to existing types (even those you don't own).
- **Closures**: Self-contained blocks of functionality.

## 💡 Quick Tips

### 1. Safety First
Use `guard` for early exits and to keep code clean of nested `if` statements.

### 2. Modern Syntax
Swift is designed to be concise; use trailing closures and `$0` shorthand for brevity.

### 3. Swift Package Manager
Manage dependencies easily with `Package.swift`.
