/-
  # Interactive Exercises: Lean 4 Programming & Proofs

  Replace the `sorry` placeholders with your own solutions!
  If you get stuck, hints are provided in comments, and full solutions
  are available in `Tutorial/Solutions.lean`.
-/

import Tutorial.Programming.DataStructures

namespace Exercises

open Programming.DataStructures

/-! ## Part 1: Programming Exercises -/

-- Exercise P1: Define the Fibonacci function recursively.
-- fib(0) = 0, fib(1) = 1, fib(n+2) = fib(n+1) + fib(n)
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n   -- try writing your own!

#eval fib 7  -- Expected: 13


-- Exercise P2: Write a function `filterEven` that takes a `List Nat` and returns only even numbers.
-- Hint: `x % 2 == 0` checks if x is even.
def filterEven (xs : List Nat) : List Nat :=
  sorry

-- Uncomment to test once implemented:
-- #eval filterEven [1, 2, 3, 4, 5, 6, 7, 8]  -- Expected: [2, 4, 6, 8]


-- Exercise P3: Compute the depth (height) of a `BinaryTree α`.
-- A leaf has depth 0, and a node has depth 1 + max(left_depth, right_depth).
-- Hint: Use `Nat.max a b`.
def treeDepth {α : Type} (t : BinaryTree α) : Nat :=
  sorry


-- Exercise P4: Safely retrieve the last element of a List as an `Option α`.
-- Hint: Pattern match on `[]`, `[x]`, and `_ :: xs`.
def safeLast {α : Type} (xs : List α) : Option α :=
  sorry


/-! ## Part 2: Proof Exercises -/

-- Exercise T1: Prove that `P ∧ Q` implies `P`.
-- Hint: Use `exact h.1` or `obtain ⟨hp, _⟩ := h`.
theorem and_elim_left (P Q : Prop) (h : P ∧ Q) : P := by
  sorry


-- Exercise T2: Prove Modus Tollens: If P implies Q, and Q is false, then P is false.
-- Hint: `¬P` is `P → False`. Introduce `hp : P`, apply `hpq`, then apply `hnq`.
theorem modus_tollens (P Q : Prop) (hpq : P → Q) (hnq : ¬Q) : ¬P := by
  sorry


-- Exercise T3: Prove that `n + 0 = 0 + n` for any `n : Nat`.
-- Hint: You can use `omega`, or induction on `n` with `rw [Nat.add_zero]`.
theorem add_comm_zero (n : Nat) : n + 0 = 0 + n := by
  sorry


-- Exercise T4: Prove that mapping the identity function over any list returns the same list.
-- Hint: Use `induction xs with | nil => ... | cons x xs ih => ...`.
theorem list_map_id {α : Type} (xs : List α) : xs.map (fun x => x) = xs := by
  sorry

end Exercises
