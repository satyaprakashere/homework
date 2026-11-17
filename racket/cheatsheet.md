# Racket Learning Cheat Sheet 🐙

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `racket main.rkt` | Run a script. |
| `raco make main.rkt` | Compile to bytecode. |
| `raco test main.rkt` | Run tests. |

## 🏗 Advanced Concepts

- **[Macros](./advanced/macros.rkt)**: Syntactic abstraction and DSL creation.

## 💡 Quick Tips

### 1. Modules
Every file is a module: `#lang racket`.

### 2. First-Class Functions
Functions are data. `(map (lambda (x) (* x x)) '(1 2 3))`.

### 3. Tail Recursion
Always use tail-recursive forms for efficient loops.
