# Java Learning Cheat Sheet ☕️

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `javac Main.java` | Compile a class. |
| `java Main` | Run a class. |
| `mvn install` | Build with Maven. |
| `gradle build` | Build with Gradle. |
| `jstack <pid>` | Get thread dump. |

## 🏗 Language Features

### Basic Features
- **Classes & Objects**: Encapsulation and Inheritance.
- **Interfaces**: Defining contracts (Multiple inheritance of type).
- **Exceptions**: `try-catch-finally` for error handling.
- **Packages**: Namespacing and access control.
- **Collections API**: `List`, `Set`, `Map`, `Queue`.

### Advanced Features
- **[Generics Wildcards](file:///Users/prakash/Documents/homework/java/advanced/GenericsDemo.java)**: `? extends` (Producer) and `? super` (Consumer).
- **[Stream API](file:///Users/prakash/Documents/homework/java/advanced/StreamDemo.java)**: Declarative data processing with `filter`, `map`, `collect`.
- **CompletableFuture**: Asynchronous programming and task chaining.
- **Virtual Threads (Java 21)**: Lightweight concurrency (Project Loom).
- **Reflection**: Inspecting and modifying code behavior at runtime.
- **Annotations**: Metadata like `@Override`, `@Entity`.

## 💡 Quick Tips

### 1. Optional
Use `Optional<T>` to avoid `NullPointerException` and handle missing values gracefully.

### 2. Records (Java 14+)
`record Person(String name, int age) {}` - Concise, immutable data carriers.

### 3. JShell
Use the `jshell` command for a quick REPL to test Java snippets.
