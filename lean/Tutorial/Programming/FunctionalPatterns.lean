/-
  # Lesson 3: Functional Patterns & Typeclasses

  Lean 4 features powerful abstractions like higher-order functions,
  the `Option` type for safe nullability, and Haskell-style typeclasses.
-/

namespace Programming.FunctionalPatterns

/-! ## 1. Higher-Order Functions on Lists -/

def numbers : List Nat := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

-- Mapping: transforming each element
def doubled : List Nat := numbers.map (fun x => x * 2)
#eval doubled

-- Filtering: keeping only elements matching a predicate
def evens : List Nat := numbers.filter (fun x => x % 2 == 0)
#eval evens

-- Folding / Reduction:
-- Summing elements using foldl:
def sumList (xs : List Nat) : Nat :=
  xs.foldl (· + ·) 0

#eval sumList numbers   -- 55

-- Folding with custom step:
def productList (xs : List Nat) : Nat :=
  xs.foldl (· * ·) 1

#eval productList [1, 2, 3, 4, 5]   -- 120


/-! ## 2. Safe Error Handling with Option -/

-- `Option α` has two constructors: `none` and `some a`.
def safeDivide (numerator denominator : Nat) : Option Nat :=
  if denominator == 0 then
    none
  else
    some (numerator / denominator)

#eval safeDivide 10 2   -- some 5
#eval safeDivide 10 0   -- none

-- Safely getting the head of a list:
def safeHead {α : Type} : List α → Option α
  | [] => none
  | x :: _ => some x

#eval safeHead [42, 100]  -- some 42
#eval safeHead ([] : List Nat)  -- none

-- Chaining Option values using monadic operators or pattern matching:
def divideAndDouble (n d : Nat) : Option Nat :=
  match safeDivide n d with
  | none => none
  | some q => some (q * 2)

#eval divideAndDouble 20 4   -- some 10
#eval divideAndDouble 20 0   -- none


/-! ## 3. Typeclasses: Defining Ad-Hoc Polymorphism -/

-- Suppose we want a typeclass for types that can be summarized as a badge or string.
class Summary (α : Type) where
  summarize : α → String

-- Instance for Nat:
instance : Summary Nat where
  summarize n := s!"Number: {n}"

-- Instance for Bool:
instance : Summary Bool where
  summarize b := if b then "Status: OK" else "Status: FAILED"

-- Instance for List of anything that implements Summary:
instance [Summary α] : Summary (List α) where
  summarize xs :=
    let items := xs.map Summary.summarize
    s!"[{String.intercalate ", " items}]"

#eval Summary.summarize (42 : Nat)
#eval Summary.summarize true
#eval Summary.summarize ([10, 20, 30] : List Nat)


/-! ## 4. Operator Overloading with Standard Typeclasses -/

structure Vector2 where
  x : Float
  y : Float
deriving Repr

-- Overload the `+` operator for Vector2 by instantiating `Add`:
instance : Add Vector2 where
  add v1 v2 := { x := v1.x + v2.x, y := v1.y + v2.y }

-- Overload `ToString` for custom printing:
instance : ToString Vector2 where
  toString v := s!"⟨{v.x}, {v.y}⟩"

def v1 : Vector2 := { x := 1.5, y := 2.5 }
def v2 : Vector2 := { x := 3.0, y := -1.0 }

#eval (v1 + v2)
#eval toString (v1 + v2)   -- "⟨4.500000, 1.500000⟩"

end Programming.FunctionalPatterns
