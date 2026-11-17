type shape =
  | Circle of float
  | Rectangle of float * float

let area s =
  match s with
  | Circle r -> 3.14159 *. r *. r
  | Rectangle (w, h) -> w *. h

let run_demo () =
  print_endline "\n--- 1. OCaml Variants Demo ---";
  let c = Circle 5.0 in
  Printf.printf "Area: %f\n" (area c)
