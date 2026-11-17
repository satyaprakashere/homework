# error_handling.roc
# Run with: roc error_handling.roc
# Run tests with: roc test error_handling.roc
#
# Topics: Result type (Ok/Err), match on Result, ?? default, ? propagation
#
# Roc uses Result for errors — no exceptions.
# A Result is either Ok(value) or Err(error).
#
# Note: .map() on Result requires an opaque single-payload type.
# For standard [Ok(a), Err(b)] unions, use match instead.

# --- Basic Result ---
parse_positive = |n| {
    if n > 0 { Ok(n) } else { Err("Expected positive, got ${n.to_str()}") }
}

expect parse_positive(5)  == Ok(5)
expect parse_positive(-3) == Err("Expected positive, got -3")

# --- Transform Result with match ---
doubled_if_positive = |n| {
    match parse_positive(n) {
        Ok(x)    => Ok(x * 2)
        Err(msg) => Err(msg)
    }
}

expect doubled_if_positive(4)  == Ok(8)
expect doubled_if_positive(-1) == Err("Expected positive, got -1")

# --- ?? operator: unwrap Ok, or use a default on Err ---
expect (Ok(42) ?? 0)       == 42
expect (Err("bad") ?? 0)   == 0

# --- ? operator: propagate errors early ---
# Inside a function returning Result, `expr?` unwraps Ok or returns Err.
validate_range = |n| {
    if n <= 100 { Ok(n) } else { Err("${n.to_str()} exceeds max of 100") }
}

process = |n| {
    a = parse_positive(n)?      # returns Err early if not positive
    b = validate_range(a)?      # returns Err early if > 100
    Ok("Result is ${b.to_str()}")
}

expect process(42)  == Ok("Result is 42")
expect process(-1)  == Err("Expected positive, got -1")
expect process(999) == Err("999 exceeds max of 100")

# --- match on Result ---
describe_result = |result| {
    match result {
        Ok(v)    => "OK: ${v.to_str()}"
        Err(msg) => "ERR: ${msg}"
    }
}

# Use describe_result on concrete Results (not bare Err("...") which is ambiguous)
expect describe_result(process(42)) == "OK: Result is 42"
expect describe_result(process(-1)) == "ERR: Expected positive, got -1"

main! = |_args| {
    inputs = [-5, 0, 42, 200, 75]

    for n in inputs {
        msg = describe_result(process(n))
        echo!("Input ${n.to_str()} -> ${msg}\n")
    }

    Ok({})
}
