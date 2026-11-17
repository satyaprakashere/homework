# Clojure Learning Cheat Sheet λ

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `lein new <name>` | Create a new Leiningen project. |
| `lein repl` | Start an interactive REPL. |
| `lein run` | Run the main function. |
| `clj -M -m <ns>` | Run a namespace with Clojure CLI. |

## 🏗 Language Features

### Basic Features (LeetCode)
- **Persistent Data Structures**: Lists (Stack), Vectors (Queue), Maps, Sets.
- **Destructuring**: `(let [{:keys [x y]} point] ...)`.
- **Sequence Functions**: `map`, `filter`, `reduce`, `group-by`, `frequencies`.
- **Loop / Recur**: `(loop [i 0] (if (< i 10) (recur (inc i)) i))`.
- **Threading Macros**: `->` (thread-first), `->>` (thread-last).

### Advanced Features
- **[Recursion Schemes](./advanced/recursion_schemes.clj)**: Abstracting recursion with `ana`, `cata`, and `hylo` morphisms.
- **[Transducers](./advanced/transducers.clj)**: Composable algorithmic transformations that are decoupled from collection types.
- **Macros**: Compile-time metaprogramming for DSL creation.
- **Core.Async**: CSP-style concurrency using channels and `go` blocks.
- **Protocols & Multi-methods**: Solving the expression problem with polymorphism.

## 💡 Quick Tips

### 1. The REPL
Clojure development is REPL-driven. Evaluate code snippets live as you build.

### 2. Immutability
All data is immutable. Transformations return new copies, making concurrency safer.

### 3. Java Interop
Call any Java method directly: `(.toUpperCase "hello")`.
