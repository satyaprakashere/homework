# control_flow.roc
# Run with: roc control_flow.roc
# Run tests with: roc test control_flow.roc
#
# Topics: if/else expressions, match (pattern matching)
#
# KEY SYNTAX RULES for this Roc nightly:
#   - if/else: `if condition { body } else { body }` — else must be on the SAME line as closing `}`
#   - No `then` keyword when using braces
#   - One-liner: `if condition "value" else "other"` — no braces, no then
#   - match: `match value { Pattern => result }`  (NOT `when value is`)
#   - Booleans are `True` and `False` (NOT `Bool.true`/`Bool.false`)

# --- if / else ---
# `if` is an expression — it evaluates to a value.
# One-liner form (no braces): `if condition value else value`
classify_number = |n| {
    if n > 0 { "positive" } else if n < 0 { "negative" } else { "zero" }
}

expect classify_number(5) == "positive"
expect classify_number(-3) == "negative"
expect classify_number(0) == "zero"

# --- match (pattern matching) ---
# `match` is Roc's powerful pattern matching expression.
# Branches use `=>` and must be exhaustive.

day_type = |day| {
    match day {
        "Saturday" | "Sunday" => "Weekend"
        "Monday" | "Tuesday" | "Wednesday" | "Thursday" | "Friday" => "Weekday"
        _ => "Unknown day"
    }
}

expect day_type("Saturday") == "Weekend"
expect day_type("Monday") == "Weekday"
expect day_type("Holiday") == "Unknown day"

# Matching on numbers
describe_score = |score| {
    match score {
        100 => "Perfect!"
        90 | 80 => "Great job!"
        70 | 60 => "Not bad."
        _ => if score < 60 { "Keep practicing." } else { "Off the charts!" }
    }
}

expect describe_score(100) == "Perfect!"
expect describe_score(90) == "Great job!"
expect describe_score(55) == "Keep practicing."

# --- Booleans: True and False (uppercase) ---
toggle = |b| if b == True { False } else { True }

expect toggle(True) == False
expect toggle(False) == True

main! = |_args| {
    echo!("${classify_number(42)}\n")
    echo!("${classify_number(-7)}\n")
    echo!("${classify_number(0)}\n")

    echo!("${day_type("Friday")}\n")
    echo!("${day_type("Sunday")}\n")

    echo!("${describe_score(90)}\n")
    echo!("${describe_score(45)}\n")

    Ok({})
}
