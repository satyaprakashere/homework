/-
  # Reference Solutions for Exercises

  Check here if you get stuck on any of the exercises in `Exercises.lean`!
-/

import Tutorial.Programming.DataStructures

namespace Solutions

open Programming.DataStructures

/-! ### Programming Solutions -/

-- 1. Fibonacci
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

-- 2. Filter Even numbers
def filterEven (xs : List Nat) : List Nat :=
  xs.filter (fun x => x % 2 == 0)

-- 3. Tree Depth
def treeDepth {α : Type} : BinaryTree α → Nat
  | BinaryTree.leaf => 0
  | BinaryTree.node l _ r => 1 + Nat.max (treeDepth l) (treeDepth r)

-- 4. Safe Last
def safeLast {α : Type} : List α → Option α
  | [] => none
  | [x] => some x
  | _ :: xs => safeLast xs


/-! ### Proof Solutions -/

-- 1. AND elimination left
theorem and_elim_left (P Q : Prop) (h : P ∧ Q) : P := by
  exact h.1

-- 2. Modus tollens: (P → Q) → ¬Q → ¬P
theorem modus_tollens (P Q : Prop) (hpq : P → Q) (hnq : ¬Q) : ¬P := by
  intro hp
  have hq : Q := hpq hp
  exact hnq hq

-- 3. Commutativity with zero: n + 0 = 0 + n
theorem add_comm_zero (n : Nat) : n + 0 = 0 + n := by
  omega

-- 4. Functor identity law for List map
theorem list_map_id {α : Type} (xs : List α) : xs.map (fun x => x) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    dsimp [List.map]
    rw [ih]

end Solutions
