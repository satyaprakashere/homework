/-
  # Lesson 4: Monads, Do-Notation & IO

  Lean 4 has a unique superpower: despite being purely functional,
  it supports imperative-style syntax using `do` notation with `let mut` (mutable variables)
  and `for` loops, while guaranteeing referential transparency!
-/

namespace Programming.MonadsAndIO

/-! ## 1. The IO Monad -/

-- A simple IO action:
def greet (name : String) : IO Unit := do
  IO.println s!"Hello, {name}! Welcome to Lean 4."

-- Chaining IO actions:
def promptUser : IO Unit := do
  IO.println "--- System Diagnostic ---"
  IO.println "All systems nominal."


/-! ## 2. Imperative-Style Programming with `let mut` and `for` -/

-- Lean 4 compiles `let mut` safely using functional state-passing or in-place mutation
-- when reference count is 1 (destructive updates!).
def sumArrayImperative (xs : Array Nat) : Nat := Id.run do
  let mut total := 0
  for x in xs do
    total := total + x
  return total

#eval sumArrayImperative #[10, 20, 30, 40]  -- 100

-- Finding the maximum element imperatively:
def findMax (xs : List Nat) : Option Nat := Id.run do
  let mut maxVal : Option Nat := none
  for x in xs do
    match maxVal with
    | none => maxVal := some x
    | some m => if x > m then maxVal := some x
  return maxVal

#eval findMax [3, 19, 7, 42, 12]  -- some 42
#eval findMax []                  -- none


/-! ## 3. Error Handling with the `Except` Monad -/

-- `Except ε α` represents either an error of type `ε` or a value of type `α`.
inductive MathError where
  | divisionByZero
  | negativeSquareRoot
deriving Repr

def checkedSqrt (x : Float) : Except MathError Float := do
  if x < 0.0 then
    Except.error MathError.negativeSquareRoot
  else
    Except.ok (Float.sqrt x)

def checkedDiv (n d : Float) : Except MathError Float := do
  if d == 0.0 then
    Except.error MathError.divisionByZero
  else
    Except.ok (n / d)

-- Combining operations inside the Except monad:
def computeFormula (a b : Float) : Except MathError Float := do
  let ratio ← checkedDiv a b
  let result ← checkedSqrt ratio
  return result

#eval computeFormula 16.0 4.0   -- Except.ok 2.0
#eval computeFormula 16.0 0.0   -- Except.error MathError.divisionByZero
#eval computeFormula (-16.0) 4.0 -- Except.error MathError.negativeSquareRoot

end Programming.MonadsAndIO
