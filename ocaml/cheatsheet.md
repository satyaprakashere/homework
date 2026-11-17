# OCaml Learning Cheat Sheet 🐫

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `ocamlc main.ml` | Compile to bytecode. |
| `ocamlopt main.ml` | Compile to native code. |
| `utop` | Advanced REPL. |
| `dune build` | Build with Dune. |

## 🏗 Advanced Concepts

- **[Variants](file:///Users/prakash/Documents/homework/ocaml/advanced/variants.ml)**: Sum types and pattern matching.

## 💡 Quick Tips

### 1. Let Bindings
`let x = 5 in x + x` - Immutable by default.

### 2. Functional First
Recursive functions need the `rec` keyword: `let rec fact n = ...`

### 3. Modules
Used for namespacing and abstraction.
