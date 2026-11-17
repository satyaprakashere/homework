/-
  # Lesson 8: Structural Induction on Lists & Program Verification

  The true power of Lean 4 is writing pure functional code
  and mathematically proving that it behaves correctly for ALL inputs.
-/

namespace Proofs.ListTheorems

/-! ## 1. Length of Concatenation -/

-- Theorem: The length of concatenating two lists is the sum of their lengths.
theorem length_append {α : Type} (xs ys : List α) :
    (xs ++ ys).length = xs.length + ys.length := by
  induction xs with
  | nil =>
    -- Base case: ([] ++ ys).length = [].length + ys.length
    simp
  | cons x xs ih =>
    -- Inductive step:
    -- ((x :: xs) ++ ys).length = (x :: xs).length + ys.length
    simp [ih]
    omega


/-! ## 2. Distributivity of `map` over Append -/

theorem map_append {α β : Type} (f : α → β) (xs ys : List α) :
    (xs ++ ys).map f = xs.map f ++ ys.map f := by
  induction xs with
  | nil =>
    -- Base case: ([] ++ ys).map f = [].map f ++ ys.map f
    rfl
  | cons x xs ih =>
    -- Inductive step:
    dsimp [List.map]
    rw [ih]


/-! ## 3. Reverse Properties and Involution -/

-- Helper lemma: reverse distributes over append (with order flipped!)
theorem reverse_append {α : Type} (xs ys : List α) :
    (xs ++ ys).reverse = ys.reverse ++ xs.reverse := by
  induction xs with
  | nil =>
    simp
  | cons x xs ih =>
    simp [ih]

-- Main theorem: Reversing a list twice yields the original list!
theorem reverse_reverse {α : Type} (xs : List α) :
    xs.reverse.reverse = xs := by
  induction xs with
  | nil =>
    -- Base case: [].reverse.reverse = []
    rfl
  | cons x xs ih =>
    -- Inductive step:
    simp [ih]

end Proofs.ListTheorems
