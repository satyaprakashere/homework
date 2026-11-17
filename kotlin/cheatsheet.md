# Kotlin Learning Cheat Sheet 🏗️

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `kotlinc main.kt -include-runtime -d main.jar` | Compile to JAR. |
| `java -jar main.jar` | Run the JAR. |
| `gradle build` | Build with Gradle. |
| `mvn install` | Build with Maven. |

## 🏗 Language Features

### Basic Features
- **Null Safety**: Types are non-nullable by default: `val name: String`.
- **Data Classes**: Auto-generated `toString`, `equals`, `hashCode`: `data class User(...)`.
- **Val vs Var**: `val` for constants (immutable), `var` for variables.
- **Smart Casts**: Compiler automatically casts types after `is` checks.
- **When Expression**: Better version of `switch`.

### Advanced Features
- **[Coroutines](./advanced/Coroutines.kt)**: Lightweight concurrency with `suspend` functions.
- **Flow**: Reactive streams built on coroutines.
- **Extension Functions**: Add methods to any class: `fun String.greet() { ... }`.
- **Lambdas with Receivers**: Basis for Kotlin DSLs (e.g., `buildString { ... }`).
- **Sealed Classes**: Restricted class hierarchies for safer `when` matches.

## 💡 Quick Tips

### 1. Interoperability
Kotlin is 100% interoperable with Java. You can call Java from Kotlin and vice-versa.

### 2. Concise Syntax
Use single-expression functions: `fun sum(a: Int, b: Int) = a + b`.

### 3. Scope Functions
Use `let`, `run`, `with`, `apply`, and `also` for cleaner code blocks.
