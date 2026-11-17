/-
  # Lesson 7: Mathematical Induction on Natural Numbers

  Induction is the fundamental proof technique for reasoning about recursive programs
  and properties of natural numbers.
-/

namespace Proofs.Induction

/-! ## 1. Basic Induction on `Nat` -/

-- Proving that 0 + n = n for all n.
-- (Note: In Lean's definition of addition, `n + 0 = n` is true by definition/rfl,
-- but `0 + n = n` requires induction!)

theorem zero_add_nat (n : Nat) : 0 + n = n := by
  induction n with
  | zero =>
    -- Base case: 0 + 0 = 0
    rfl
  | succ n ih =>
    -- Inductive step: assuming 0 + n = n (ih), prove 0 + (n + 1) = n + 1
    -- Lean's definition of `+` on the right unfolds: 0 + (n + 1) = (0 + n) + 1
    rw [Nat.add_succ]
    rw [ih]


/-! ## 2. Induction on Recursive Functions -/

-- Recursive doubling function:
def double : Nat → Nat
  | 0 => 0
  | n + 1 => double n + 2

#eval double 5   -- 10

-- Proving that `double n = 2 * n` for all n:
theorem double_eq_two_mul (n : Nat) : double n = 2 * n := by
  induction n with
  | zero =>
    -- Base case: double 0 = 2 * 0
    rfl
  | succ n ih =>
    -- Inductive step: double (n + 1) = double n + 2 = 2 * n + 2 = 2 * (n + 1)
    dsimp [double]
    rw [ih]
    omega


/-! ## 3. Proving Associativity of Addition -/

theorem add_assoc_custom (a b c : Nat) : (a + b) + c = a + (b + c) := by
  induction c with
  | zero =>
    -- Base case: (a + b) + 0 = a + (b + 0)
    rfl
  | succ c ih =>
    -- Inductive step:
    -- (a + b) + (c + 1) = ((a + b) + c) + 1
    -- a + (b + (c + 1)) = a + ((b + c) + 1) = (a + (b + c)) + 1
    rw [Nat.add_succ]
    rw [Nat.add_succ]
    rw [Nat.add_succ]
    rw [ih]


/-! ## 4. Commutativity of Addition -/

theorem succ_add (n m : Nat) : Nat.succ n + m = Nat.succ (n + m) := by
  induction m with
  | zero => rfl
  | succ m ih =>
    rw [Nat.add_succ, Nat.add_succ, ih]

theorem add_comm_custom (n m : Nat) : n + m = m + n := by
  induction m with
  | zero =>
    -- n + 0 = 0 + n
    rw [Nat.add_zero]
    rw [zero_add_nat]
  | succ m ih =>
    -- n + succ m = succ (n + m)
    rw [Nat.add_succ]
    rw [ih]
    rw [succ_add]

end Proofs.Induction
