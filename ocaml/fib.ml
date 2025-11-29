
let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)
;;

let fib_tail n =
  let rec aux a b i =
    if i = 0 then a
    else aux b (a + b) (i - 1)
  in aux 0 1 n
;;


(* or tail-recursive call *)
let () =
  let n = 98765432 in
  Printf.printf "fib_tail(%d) = %d\n" n (fib_tail n)
;;
