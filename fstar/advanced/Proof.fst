module Proof

val divide : a:int -> b:int{b <> 0} -> int
let divide a b = a / b

let run_demo () =
  let result = divide 10 2 in
  ()
