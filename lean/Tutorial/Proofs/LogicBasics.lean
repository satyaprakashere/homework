/-
  # Lesson 5: Logic Basics & Propositional Calculus

  In Lean 4, mathematical propositions are types (`Prop`), and proofs are terms (programs)
  of those types. This is known as the **Curry-Howard Isomorphism**.

  Lean provides two ways to write proofs:
  1. **Tactic Mode**: using `by` with interactive step-by-step tactics.
  2. **Term Mode**: writing the proof directly as an expression/function.
-/

namespace Proofs.LogicBasics

/-! ## 1. Implication (`→`) -/

-- If P is true, then P is true.
-- Tactic mode:
theorem imp_self_tactic (P : Prop) : P → P := by
  intro h   -- Assume P holds, call the hypothesis 'h'
  exact h   -- Goal is P, which is exactly 'h'

-- Term mode: identical to the identity function `fun h => h`!
theorem imp_self_term (P : Prop) : P → P :=
  fun h => h

-- Modus Ponens: From P and (P → Q), we can deduce Q.
theorem modus_ponens (P Q : Prop) (hp : P) (hpq : P → Q) : Q := by
  apply hpq  -- New goal: P
  exact hp

-- Implication transitivity:
theorem imp_trans (P Q R : Prop) (h1 : P → Q) (h2 : Q → R) : P → R := by
  intro hp
  apply h2
  apply h1
  exact hp


/-! ## 2. Conjunction (AND: `∧`) -/

-- To prove `P ∧ Q`, we must supply a proof of `P` and a proof of `Q`.
-- Tactic `constructor` splits the goal into two subgoals.
theorem and_comm_tactic (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
  -- Destruct hypothesis `h` into its components `hp` and `hq`
  obtain ⟨hp, hq⟩ := h
  constructor
  · exact hq
  · exact hp

-- In term mode, conjunction is like a pair / tuple constructor `⟨... , ...⟩`:
theorem and_comm_term (P Q : Prop) (h : P ∧ Q) : Q ∧ P :=
  ⟨h.2, h.1⟩

-- Associativity of AND:
theorem and_assoc (P Q R : Prop) : (P ∧ Q) ∧ R → P ∧ (Q ∧ R) := by
  intro ⟨⟨hp, hq⟩, hr⟩
  exact ⟨hp, ⟨hq, hr⟩⟩


/-! ## 3. Disjunction (OR: `∨`) -/

-- To prove `P ∨ Q`, we can use `apply Or.inl` (left) or `apply Or.inr` (right).
-- To use `h : P ∨ Q`, we do case analysis (`rcases` or `cases`).
theorem or_comm_tactic (P Q : Prop) (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp =>
    -- Case 1: P is true
    apply Or.inr
    exact hp
  | inr hq =>
    -- Case 2: Q is true
    apply Or.inl
    exact hq

-- Distributivity: P ∧ (Q ∨ R) → (P ∧ Q) ∨ (P ∧ R)
theorem and_distrib_or (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  obtain ⟨hp, hqr⟩ := h
  cases hqr with
  | inl hq =>
    apply Or.inl
    exact ⟨hp, hq⟩
  | inr hr =>
    apply Or.inr
    exact ⟨hp, hr⟩


/-! ## 4. Negation (`¬`) and Falsehood (`False`) -/

-- In Lean, `¬P` is defined as `P → False`.
-- Falsehood proves anything (Principle of Explosion: `exfalso`).

theorem double_neg_intro (P : Prop) : P → ¬¬P := by
  intro hp      -- Assume P
  intro hnp     -- Assume ¬P, which means P → False
  apply hnp
  exact hp

-- Contradiction tactic closes goals with conflicting hypotheses:
theorem from_contradiction (P Q : Prop) (hp : P) (hnp : ¬P) : Q := by
  contradiction

end Proofs.LogicBasics
