# Haskell Learning Cheat Sheet λ

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `ghc main.hs` | Compile to executable. |
| `ghci` | Start interactive REPL. |
| `cabal build` | Build with Cabal. |
| `stack build` | Build with Stack. |

## 🏗 Language Features

### Basic Features
- **Pure Functions**: No side effects, deterministic output.
- **Immutability**: Variables cannot be changed once bound.
- **Lazy Evaluation**: Computations are deferred until results are needed.
- **Pattern Matching**: Destructure data in function definitions.
- **Recursion**: The primary way to loop (no `for` or `while`).
- **List Comprehensions**: `[x*2 | x <- [1..10], even x]`.

### Advanced Features
- **[Monads](./advanced/Monads.hs)**: Abstracting computations with side effects (IO, Maybe, State).
- **Type Classes**: Ad-hoc polymorphism (Eq, Ord, Show, Functor, Monad).
- **Currying**: All functions technically take one argument and return a function.
- **Higher-Order Functions**: `map`, `filter`, `foldl`.
- **Algebraic Data Types (ADTs)**: `data Shape = Circle Float | Rect Float Float`.

## 💡 Quick Tips

### 1. The `do` Notation
Syntactic sugar for the `>>=` (bind) operator in Monads.

### 2. Type Inference
Haskell can usually figure out types, but explicit signatures are best practice: `f :: Int -> Int`.

### 3. Function Composition
Use the `.` operator: `(f . g) x` is equivalent to `f(g(x))`.
