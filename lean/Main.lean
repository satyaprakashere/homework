import Tutorial

open Programming.Basics
open Programming.DataStructures
open Programming.FunctionalPatterns
open Programming.MonadsAndIO
open Solutions

def main : IO Unit := do
  IO.println "=================================================="
  IO.println "       Welcome to Lean 4: Code & Proofs Demo      "
  IO.println "=================================================="
  IO.println ""

  IO.println "--- 1. Pure Functional Programming ---"
  IO.println s!"Factorial of 5: {factorial 5}"
  IO.println s!"Fibonacci of 10: {fib 10}"

  let tree : BinaryTree Nat :=
    BinaryTree.node (BinaryTree.node BinaryTree.leaf 3 BinaryTree.leaf) 5 (BinaryTree.node BinaryTree.leaf 8 BinaryTree.leaf)
  IO.println s!"Binary Tree in-order: {toListInOrder tree}"
  IO.println s!"Binary Tree depth: {treeDepth tree}"
  IO.println ""

  IO.println "--- 2. Typeclasses & Operator Overloading ---"
  let v1 : Vector2 := { x := 1.5, y := 2.5 }
  let v2 : Vector2 := { x := 3.0, y := -1.0 }
  IO.println s!"Vector addition: {v1} + {v2} = {v1 + v2}"
  IO.println ""

  IO.println "--- 3. Imperative-style `do` with `let mut` ---"
  let arr := #[10, 20, 30, 40]
  IO.println s!"Summing array #[10, 20, 30, 40] imperatively: {sumArrayImperative arr}"
  IO.println ""

  IO.println "--- 4. Verified Theorems ---"
  IO.println "All proofs in `Tutorial/Proofs/` and `Tutorial/Solutions.lean`"
  IO.println "have been formally verified by the Lean 4 kernel at compile time!"
  IO.println ""
  IO.println "Check out the files in `Tutorial/` to start learning:"
  IO.println "  • Tutorial/Programming/Basics.lean"
  IO.println "  • Tutorial/Programming/DataStructures.lean"
  IO.println "  • Tutorial/Programming/FunctionalPatterns.lean"
  IO.println "  • Tutorial/Programming/MonadsAndIO.lean"
  IO.println "  • Tutorial/Proofs/LogicBasics.lean"
  IO.println "  • Tutorial/Proofs/EqualityAndArithmetic.lean"
  IO.println "  • Tutorial/Proofs/Induction.lean"
  IO.println "  • Tutorial/Proofs/ListTheorems.lean"
  IO.println "  • Tutorial/Exercises.lean (with Solutions.lean)"
  IO.println "=================================================="
