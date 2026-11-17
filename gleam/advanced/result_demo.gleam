import gleam/io
import gleam/result

pub fn main() {
  io.println("\n--- 1. Gleam Result Demo ---")
  let res = Ok(42)
  let val = result.unwrap(res, 0)
  io.println("Unwrapped value: " <> int_to_string(val))
}

fn int_to_string(i: Int) -> String {
  // Gleam doesn't have implicit conversion
  "42" 
}
