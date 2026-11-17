# vars_and_loops.roc
# Run with: roc vars_and_loops.roc
# Run tests with: roc test vars_and_loops.roc
#
# Topics: var (mutable variables), for loops, while loops, break, return
#
# KEY SYNTAX:
#   - `var $name = value`  declares a mutable variable
#   - `$name = new_value`  reassigns it
#   - `for item in list { ... }`
#   - `while condition { ... }`
#   - `break` exits a loop early
#   - `return value` exits the function early
#   - `expr ?? default` unwraps Ok or provides a default

# --- var + while loop ---
count_down = |start| {
    var $n = start
    var $result = []

    while $n > 0 {
        $result = $result.append($n)
        $n = $n - 1
    }

    $result
}

expect count_down(5) == [5, 4, 3, 2, 1]

# --- for loop ---
sum_list = |numbers| {
    var $total = 0
    for n in numbers {
        $total = $total + n
    }
    $total
}

expect sum_list([1, 2, 3, 4, 5]) == 15

# --- early return ---
find_first = |list, predicate| {
    for item in list {
        if predicate(item) {
            return Ok(item)
        } else { {} }
    }
    Err("Not found")
}

expect find_first([1, 3, 5, 6, 7], |n| n % 2 == 0) == Ok(6)
expect find_first([1, 3, 5], |n| n % 2 == 0) == Err("Not found")

# --- while with break ---
# `expr ?? default` returns the Ok value or the default on Err
first_multiple_of = |numbers, factor| {
    var $found = Err("none")
    var $i = 0

    while $i < numbers.len() {
        n = numbers.get($i) ?? 0
        if n % factor == 0 {
            $found = Ok(n)
            break
        } else { {} }
        $i = $i + 1
    }

    $found
}

expect first_multiple_of([1, 3, 7, 9, 12, 15], 4) == Ok(12)

# Helper: join list of strings using fold
join_strs = |list, sep| {
    list.fold("", |acc, s| {
        if acc == "" { s } else { Str.concat(acc, Str.concat(sep, s)) }
    })
}

main! = |_args| {
    cd = count_down(5).map(|n| n.to_str())
    echo!("Countdown:       [${join_strs(cd, ", ")}]\n")
    echo!("Sum:             ${sum_list([10, 20, 30]).to_str()}\n")

    r1 = find_first([1, 3, 5, 6, 7], |n| n % 2 == 0)
    echo!("First even:      ${Str.inspect(r1)}\n")

    r2 = first_multiple_of([1, 3, 7, 9, 12], 4)
    echo!("First mult of 4: ${Str.inspect(r2)}\n")

    Ok({})
}
