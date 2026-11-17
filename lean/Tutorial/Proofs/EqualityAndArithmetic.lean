/-
  # Lesson 6: Equalities, Rewriting & Arithmetic

  This lesson covers:
  - `rfl`: Reflexivity of equality (computational equality)
  - `rw`: Rewriting subterms using equations
  - `simp`: The automatic simplifier
  - `calc`: Step-by-step calculational proofs
  - `omega`: Lean 4's built-in Presburger arithmetic solver
-/

namespace Proofs.EqualityAndArithmetic

/-! ## 1. Reflexivity and Computation -/

-- `rfl` proves any equality where both sides evaluate to the exact same normal form:
theorem computation_test : 2 + 2 = 4 := by
  rfl

theorem beta_reduction : (fun x : Nat => x + 1) 5 = 6 := by
  rfl


/-! ## 2. Rewriting (`rw`) -/

-- Forward rewriting:
theorem rw_forward (a b c : Nat) (h1 : a = b) (h2 : b = c) : a = c := by
  rw [h1]   -- Replaces 'a' with 'b' in the goal; goal becomes 'b = c'
  exact h2

-- Backward rewriting using `←`:
theorem rw_backward (a b c : Nat) (h1 : b = a) (h2 : b = c) : a = c := by
  rw [← h1]  -- Replaces 'a' with 'b' in the goal; goal becomes 'b = c'
  exact h2

-- Rewriting in a hypothesis using `at`:
theorem rw_at_hypothesis (a b c : Nat) (h1 : a = b) (h2 : a = c) : b = c := by
  rw [h1] at h2   -- Replaces 'a' with 'b' in 'h2'; 'h2' becomes 'b = c'
  exact h2


/-! ## 3. Calculational Proofs (`calc`) -/

-- `calc` blocks let you write chains of equalities or inequalities
-- just like you would on paper, proving each step with a justification.
theorem calc_example (x y z : Nat) (h1 : x = y + 1) (h2 : y = 2 * z) : x = 2 * z + 1 := by
  calc
    x = y + 1     := by rw [h1]
    _ = 2 * z + 1 := by rw [h2]


/-! ## 4. The Simplifier (`simp`) -/

-- `simp` repeatedly applies rewrite lemmas tagged with `@[simp]`,
-- along with standard library rules for booleans, arithmetic, and logic.
theorem simp_example (n : Nat) : n + 0 = n := by
  simp

theorem simp_bool (b : Bool) : (b && true) = b := by
  simp


/-! ## 5. Decision Procedures: The `omega` Tactic -/

-- `omega` solves goals involving linear integer and natural arithmetic
-- (addition, subtraction by a constant, multiplication by a constant, inequalities).
-- It is one of the most useful tactics in Lean 4!

theorem omega_linear (a b : Nat) (h1 : a + 3 ≤ b) (h2 : b ≤ 10) : a ≤ 7 := by
  omega

theorem omega_arith (x y : Nat) : (x + y) + 5 = y + (x + 2) + 3 := by
  omega

theorem omega_cases (n : Nat) (h : n < 3) : n = 0 ∨ n = 1 ∨ n = 2 := by
  omega

end Proofs.EqualityAndArithmetic
