
module Fib

// Nonnegative integers
type nat = x:int { x >= 0 }

// Exponential-time reference version
let rec fib_naive (n:nat) : Tot nat (decreases n) =
  if n <= 1 then n
  else fib_naive (n - 1) + fib_naive (n - 2)

// Linear-time version with accumulators
let rec fib_aux (n:nat) (a:nat) (b:nat) : Tot nat (decreases n) =
  if n = 0 then a
  else fib_aux (n - 1) b (a + b)

// Public API
let fib (n:nat) : Tot nat = fib_aux n 0 1
