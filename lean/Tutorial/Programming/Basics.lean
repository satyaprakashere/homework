/-
  # Lesson 1: Lean 4 as a Programming Language — The Basics

  Lean 4 is a modern, purely functional programming language with:
  - Strong static typing with type inference
  - Eager (strict) evaluation by default
  - Immutable data by default
  - Direct compilation to C for high performance
-/

namespace Programming.Basics

/-! ## 1. Basic Values and Types -/

-- Definitions use the `def` keyword.
-- Type annotations are written with `: Type`.
def anInteger : Int := -42
def aNaturalNumber : Nat := 100  -- `Nat` represents non-negative integers (0, 1, 2, ...)
def aFloat : Float := 3.14159
def aString : String := "Hello, Lean 4!"
def aBoolean : Bool := true

-- Lean 4 has type inference, so types can often be omitted:
def inferredNumber := 250   -- Inferred as Nat

-- You can evaluate expressions at compile time using `#eval`:
#eval 2 + 3 * 4             -- Outputs: 14
#eval s!"String interpolation: {aString}, count = {aNaturalNumber}"


/-! ## 2. Functions and Lambdas -/

-- Simple function definition with arguments:
def add (a : Nat) (b : Nat) : Nat :=
  a + b

-- Multiple parameters can share the same type:
def multiply (x y : Nat) : Nat :=
  x * y

-- Functions are first-class citizens. Anonymous functions (lambdas) use `fun` or `λ`:
def square : Nat → Nat := fun x => x * x

-- Lean supports pipeline operators `|>` and `<|`:
#eval 5 |> add 3 |> square   -- (5 + 3)^2 = 64


/-! ## 3. Conditionals and Let-Bindings -/

-- `if ... then ... else ...` is an expression (it returns a value):
def maxNat (a b : Nat) : Nat :=
  if a ≥ b then a else b

-- Local definitions using `let`:
def quadratic (a b c x : Float) : Float :=
  let term1 := a * x * x
  let term2 := b * x
  term1 + term2 + c

#eval quadratic 1.0 2.0 1.0 3.0   -- 1*(9) + 2*(3) + 1 = 16.0


/-! ## 4. Collections: Lists and Tuples -/

-- Tuples have fixed length and can have heterogeneous types:
def person : String × Nat × Bool := ("Alice", 28, true)
#eval person.1      -- "Alice"
#eval person.2.1    -- 28

-- Lists are homogeneous and singly-linked:
def sampleList : List Nat := [1, 2, 3, 4, 5]

-- List operations:
#eval sampleList.length          -- 5
#eval sampleList.reverse         -- [5, 4, 3, 2, 1]
#eval 0 :: sampleList            -- Cons operator: [0, 1, 2, 3, 4, 5]
#eval sampleList ++ [6, 7]       -- Append: [1, 2, 3, 4, 5, 6, 7]


/-! ## 5. Exercises to try -/

-- Exercise B1: Define a function `factorial (n : Nat) : Nat` using structural recursion:
def factorial : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 5   -- 120

end Programming.Basics
