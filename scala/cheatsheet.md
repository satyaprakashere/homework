# Scala Learning Cheat Sheet 🧬

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `scala --server=false <File>.scala` | Run a Scala 3 script or application directly. |
| `scalac <File>.scala` | Compile source code to JVM bytecode. |
| `scala <MainClassName>` | Run compiled bytecode. |
| `scala repl` | Launch the interactive Scala REPL shell. |

---

## 📚 Interactive Learning Examples

All example files are fully self-contained and runnable with `scala --server=false <File>.scala`.

| Topic | File | Highlights |
| :--- | :--- | :--- |
| **Basics** | [Basics.scala](./Basics.scala) | `val` vs `var`, string interpolators (`s`, `f`, `raw`), `if` expressions, for-comprehensions, tuples |
| **Functions** | [Functions.scala](./Functions.scala) | Default/named args, lambdas, higher-order functions, currying, `@tailrec` recursion |
| **Collections** | [Collections.scala](./Collections.scala) | `List`, `Vector`, `Set`, `Map`, `foldLeft`, `flatMap`, `groupBy`, `partition` |
| **Data Modeling** | [DataModeling.scala](./DataModeling.scala) | `case class`, `.copy()`, Scala 3 `enum`, Algebraic Data Types (ADTs), Expression trees |
| **Pattern Matching** | [PatternMatching.scala](./PatternMatching.scala) | Type patterns, pattern guards (`if`), case class destructuring, list matching (`head :: tail`) |
| **Error Handling** | [ErrorHandling.scala](./ErrorHandling.scala) | Idiomatic functional errors: `Option` (`Some`/`None`), `Either` (`Left`/`Right`), `Try` |
| **Traits & Classes** | [TraitsAndClasses.scala](./TraitsAndClasses.scala) | Traits with default implementations, mixins, companion objects, encapsulation |
| **Contextual Abstractions** | [ContextualAbstractions.scala](./ContextualAbstractions.scala) | Modern Scala 3: `extension` methods, `given` instances, `using` parameters, type classes |
| **Concurrency** | [Concurrency.scala](./Concurrency.scala) | Asynchronous `Future`, `ExecutionContext`, `Future.sequence`, composing with `for` |
| **Algorithms** | [fib.scala](./fib.scala) | Fibonacci sequence: naive recursive, tail recursive, and infinite `LazyList` stream |

---

## 💡 Quick Tips

### 1. Immutability by Default
Prefer `val` over `var` and immutable collections (`List`, `Vector`, `Map`). Modify state by producing new values with `.copy()` or transform functions.

### 2. Expressions, Not Statements
Almost everything in Scala produces a value:
```scala
val status = if score >= 60 then "Passed" else "Failed"
```

### 3. Case Classes & Enums
```scala
case class Person(name: String, age: Int)

enum TrafficLight:
  case Red, Yellow, Green
```

### 4. Scala 3 Extension Methods
Add methods to existing classes without inheritance:
```scala
extension (s: String)
  def shout: String = s.toUpperCase + "!"
```
