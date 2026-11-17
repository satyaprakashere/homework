import gleam/io
import gleam/int
import gleam/result

pub fn main() {
  let res = Ok(42)
  let val = result.unwrap(res, 0)
  io.println("Unwrapped value: " <> int_to_string(val))

  // These two functions do exactly the same thing, but one is written with `use`, and one without.
  let _ = with_use()    |> echo
  let _ = without_use() |> echo
}

fn int_to_string(i: Int) -> String {
  int.to_string(i)
}

fn with_use() -> Result(String, Nil) {
  use username <- result.try(get_username())
  use password <- result.try(get_password())
  use greeting <- result.map(log_in(username, password))
  greeting <> ", " <> username
}

fn without_use() -> Result(String, Nil) {
  result.try(get_username(), fn(username) {
    result.try(get_password(), fn(password) {
      result.map(log_in(username, password), fn(greeting) {
        greeting <> ", " <> username
      })
    })
  })
}

// Here are some pretend functions for this example:
fn get_username() -> Result(String, Nil) {
  Ok("alice")
}

fn get_password() -> Result(String, Nil) {
  Ok("hunter2")
}

fn log_in(_username: String, _password: String) -> Result(String, Nil) {
  Ok("Welcome")
}
