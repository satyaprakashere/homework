# pipeline_and_composition.roc
# Run with: roc pipeline_and_composition.roc
# Run tests with: roc test pipeline_and_composition.roc
#
# Topics: the pipe operator |>, method-call dot notation, chaining
#
# KEY SYNTAX for |>:
#   - `value |> fn_name` — works when piping into a named function
#   - `value |> (|x| expr)` — piping into a lambda REQUIRES parentheses
#   - Chaining: pipe multiple times

# Helper: join a list of strings with a separator
join_strs = |list, sep| {
    list.fold("", |acc, s| {
        if acc == "" { s } else { Str.concat(acc, Str.concat(sep, s)) }
    })
}

# --- The pipe operator |> ---
# |> passes the left-hand value as the FIRST argument of the right-hand call.
# When piping into a lambda, wrap it in parentheses.

double_evens_sum =
    [1, 2, 3, 4, 5]
    |> (|xs| xs.map(|n| n * 2))        # [2, 4, 6, 8, 10]
    |> (|xs| xs.keep_if(|n| n > 4))    # [6, 8, 10]
    |> (|xs| xs.fold(0, |a, n| a + n)) # 24

expect double_evens_sum == 24

# --- Method-call dot notation ---
# list.map(fn) is equivalent to passing list as the first argument.
names = ["alice", "bob", "charlie"]

# Keep names longer than 3 chars, then manually reverse the list
long_names =
    names
    |> (|xs| xs.keep_if(|s| s.count_utf8_bytes() > 3))
    |> (|xs| xs.fold([], |acc, s| acc.prepend(s)))

expect long_names == ["charlie", "alice"]

# --- ?? operator: unwrap Ok or provide a default ---
parsed     = I64.from_str("42") ?? 0
parse_fail = I64.from_str("nope") ?? -1

expect parsed == 42
expect parse_fail == -1

# --- Chaining on a single value ---
# Sort ascending then manually reverse to get descending order
result_str =
    [3, 1, 4, 1, 5, 9]
    |> (|xs| xs.sort())
    |> (|xs| xs.fold([], |acc, n| acc.prepend(n)))  # reverse
    |> (|xs| xs.map(|n| n.to_str()))
    |> (|xs| join_strs(xs, " > "))

expect result_str == "9 > 5 > 4 > 3 > 1 > 1"

main! = |_args| {
    echo!("Double-evens sum:  ${double_evens_sum.to_str()}\n")
    echo!("Long names:        ${join_strs(long_names, ", ")}\n")
    echo!("Parsed 42:         ${parsed.to_str()}\n")
    echo!("Parsed 'nope':     ${parse_fail.to_str()}\n")
    echo!("Sorted desc:       ${result_str}\n")

    Ok({})
}
