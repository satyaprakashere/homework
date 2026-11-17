# Lean 4: Interactive Programming & Theorem Proving Tutorial

Welcome! This repository is organized as a dual-track introduction to Lean 4:
1. **Lean 4 as a Modern Functional Programming Language**
2. **Lean 4 as an Interactive Theorem Prover**

All code has been verified and compiled using the Lean 4 compiler (`lake build`).

---

## 📚 Curriculum Overview

### Part 1: Functional Programming in Lean 4

| File | Key Concepts Covered |
|------|----------------------|
| [`Tutorial/Programming/Basics.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Programming/Basics.lean) | Types (`Nat`, `Int`, `Float`, `String`, `Bool`), function definitions, lambdas (`fun x => ...`), pipelining (`\|>`), let-bindings, `#eval` and `#check`. |
| [`Tutorial/Programming/DataStructures.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Programming/DataStructures.lean) | Enums, algebraic data types (ADTs), records/`structure`, functional record updates, recursive inductive types (`BinaryTree`), BST insertion and tree traversals. |
| [`Tutorial/Programming/FunctionalPatterns.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Programming/FunctionalPatterns.lean) | Higher-order list functions (`map`, `filter`, `foldl`), safe error handling with `Option`, custom typeclasses (`class`, `instance`), operator overloading (`Add`, `ToString`). |
| [`Tutorial/Programming/MonadsAndIO.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Programming/MonadsAndIO.lean) | The `IO` monad, `do` notation, imperative-style mutable local variables (`let mut`) with functional guarantees, `for` loops, error handling with `Except`. |

---

### Part 2: Interactive Theorem Proving in Lean 4

| File | Key Concepts Covered |
|------|----------------------|
| [`Tutorial/Proofs/LogicBasics.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Proofs/LogicBasics.lean) | Propositions-as-Types (Curry-Howard), implication (`intro`, `apply`, `exact`), conjunction (`obtain`, `constructor`), disjunction (`cases`, `Or.inl`, `Or.inr`), negation (`¬P = P → False`), `contradiction`. |
| [`Tutorial/Proofs/EqualityAndArithmetic.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Proofs/EqualityAndArithmetic.lean) | Computational equality (`rfl`), equational rewriting (`rw [h]`, `rw [← h]`, `rw [h] at h2`), the simplifier (`simp`), calculational proofs (`calc`), Presburger arithmetic solver (`omega`). |
| [`Tutorial/Proofs/Induction.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Proofs/Induction.lean) | Mathematical induction on `Nat` (`induction n with \| zero => ... \| succ n ih => ...`), base cases and induction hypotheses, reasoning about recursive functions, commutativity and associativity of addition. |
| [`Tutorial/Proofs/ListTheorems.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Proofs/ListTheorems.lean) | Structural induction on lists, verifying programs: proving `(xs ++ ys).length = xs.length + ys.length`, proving `(xs ++ ys).map f = xs.map f ++ ys.map f`, proving `xs.reverse.reverse = xs`. |

---

### Part 3: Exercises & Solutions

- **[`Tutorial/Exercises.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Exercises.lean)**:
  Hands-on exercises with `sorry` placeholders for you to fill in:
  - Programming: Fibonacci, filter evens, tree depth, safe last.
  - Proofs: AND elimination, Modus Tollens, `n + 0 = 0 + n`, list map identity functor law.
- **[`Tutorial/Solutions.lean`](file:///Users/prakash/Documents/homework/lean/Tutorial/Solutions.lean)**:
  Complete, verified reference solutions.

---

## 🚀 Running and Building the Code

From the workspace root (`/Users/prakash/Documents/homework/lean`):

### 1. Build the library & verify proofs
```bash
lake build
```

### 2. Run the executable demo
```bash
lake exe demo
```

### 3. Interactive Proof Mode in the Editor
When you open any `.lean` file in an editor with the Lean 4 extension:
- Place your cursor inside any `by` proof block to inspect the **Lean Infoview**.
- The Infoview displays the exact **Tactic State**: current hypotheses (`h : ...`) and remaining goals (`⊢ ...`) at each step!
