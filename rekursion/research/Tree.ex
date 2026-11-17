defmodule Tree where
  data Tree a : Set where
    Empty : Tree a
    Node  : Tree a = a (Tree a) (Tree a)
  end

  func inorderT : Tree a -> String
  func inorderT = do
    self match
      Empty   => ""
      (a l r) => l.inorderT ++ a.show ++ r.inorderT
    end
  end

  defunc singleton : a -> Tree a
  defunc singleton a = Tree a Empty Empty
end
defmodule Fibonacci where
  defunc fibonacci n = do
    defunc recFib 1 _ b = b
    defunc recFib n a b = recFib (n-1) b (a+b)

    recFib n 0 1
  end

defmodule Main where
  defunc main = do
    println "Enter Number: "
    let number := readLine.parseInt in
      print "Fibonacci " ++ number.show ++ ": " ++ fibonacci number
  end

    #or number : Int64
    #or number = readLine.parse

private defmodule BTree where
  data BTree a : Set where
    Empty : Tree a
    Node  : Tree a = a (Tree a) (Tree a)
  end
end

if a < 0
  then do
    jsdfds
  else do
    fsdfs
  end

Integer
Nat

Int64
UInt64
Float64
Float128
Int128
UInt128

Array -> fixed size array
List -> linkedList (also an protocol)
Vector -> resizable array
Set protocol with default implementation
Map protocol with default implementation
TreeMap
TreeSet
Queue
Stack
Heap
Matrix
String
Tuple
IO
Iterator -> implicit
slice operator
range function
alorithms


for x in y
and or

[List syntax]
(tuple syntax)
{map syntax}

let res = 10 / 2
; res = 5.0

:Atom

no == operator
unicode-8

++ for list addition

IO.println
IO.print

let f = lambda x -> 2*2 end
let list = [1, true, "fdsfsd"]
; list : List[Any]


