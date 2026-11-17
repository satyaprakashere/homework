/-
  # Lesson 2: Data Structures, Inductive Types & Pattern Matching

  Inductive types are the cornerstone of both programming and mathematics in Lean.
  Every custom data structure (enums, lists, trees, ASTs) is an inductive type.
-/

namespace Programming.DataStructures

/-! ## 1. Enumerations (Simple Inductive Types) -/

inductive Weekday where
  | sunday
  | monday
  | tuesday
  | wednesday
  | thursday
  | friday
  | saturday
deriving Repr, BEq

-- Pattern matching on an inductive type:
def isWeekend (day : Weekday) : Bool :=
  match day with
  | Weekday.saturday | Weekday.sunday => true
  | _ => false

#eval isWeekend Weekday.saturday  -- true
#eval isWeekend Weekday.monday    -- false


/-! ## 2. Algebraic Data Types (Variants with Payloads) -/

inductive Shape where
  | circle (radius : Float)
  | rectangle (width height : Float)
deriving Repr

def Shape.area : Shape → Float
  | .circle r => 3.14159 * r * r
  | .rectangle w h => w * h

#eval (Shape.circle 5.0).area
#eval (Shape.rectangle 4.0 6.0).area


/-! ## 3. Structures (Records / Product Types) -/

-- Structures define types with named fields. Lean automatically generates constructors and getters.
structure Point2D where
  x : Float
  y : Float
deriving Repr, BEq

def origin : Point2D := { x := 0.0, y := 0.0 }
def pt1 : Point2D := { x := 3.0, y := 4.0 }

-- Field access:
#eval pt1.x
#eval pt1.y

-- Structure update syntax (functional update creating a new record):
def pt2 : Point2D := { pt1 with x := 10.0 }
#eval pt2   -- { x := 10.0, y := 4.0 }

def distanceOrigin (p : Point2D) : Float :=
  Float.sqrt (p.x * p.x + p.y * p.y)

#eval distanceOrigin pt1   -- 5.0


/-! ## 4. Recursive Inductive Types: Binary Trees -/

-- Polymorphic binary tree type over an arbitrary type `α`:
inductive BinaryTree (α : Type) where
  | leaf
  | node (left : BinaryTree α) (value : α) (right : BinaryTree α)
deriving Repr

open BinaryTree

-- Example tree:
--        5
--       / \
--      3   8
def myTree : BinaryTree Nat :=
  node (node leaf 3 leaf) 5 (node leaf 8 leaf)

-- Tree size (number of nodes):
def treeSize {α : Type} : BinaryTree α → Nat
  | leaf => 0
  | node left _ right => 1 + treeSize left + treeSize right

#eval treeSize myTree   -- 3

-- In-order traversal to a List:
def toListInOrder {α : Type} : BinaryTree α → List α
  | leaf => []
  | node left val right => toListInOrder left ++ [val] ++ toListInOrder right

#eval toListInOrder myTree  -- [3, 5, 8]

-- Tree insertion for Binary Search Tree:
def bstInsert (x : Nat) : BinaryTree Nat → BinaryTree Nat
  | leaf => node leaf x leaf
  | node left val right =>
    if x < val then
      node (bstInsert x left) val right
    else if x > val then
      node left val (bstInsert x right)
    else
      node left val right

#eval toListInOrder (bstInsert 6 myTree)  -- [3, 5, 6, 8]

end Programming.DataStructures
