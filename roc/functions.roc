# functions.roc
# Run with: roc functions.roc
# Run tests with: roc test functions.roc
#
# Topics: defining functions (lambdas), calling functions,
#         pure vs effectful functions, block bodies

# --- Pure Functions ---
# Functions are values assigned with `=`, using lambda syntax: |args| body

greet = |name| "Hello, ${name}!"

add = |a, b| a + b

add_and_double = |a, b| (add(a, b)) * 2

# Block body: multiple statements, last expression is the return value
describe_number = |n| {
    doubled = n * 2
    tripled = n * 3
    "n=${n.to_str()}, doubled=${doubled.to_str()}, tripled=${tripled.to_str()}"
}

# --- Tests ---
# `expect` is Roc's lightweight testing keyword.
# Run tests with: roc test functions.roc
expect greet("World") == "Hello, World!"
expect add(2, 3) == 5
expect add_and_double(3, 4) == 14

# --- Effectful Functions (end with !) ---
# Functions performing side effects (I/O, etc.) end with `!` by convention.
print_greeting! = |name| {
    echo!("${greet(name)}\n")
}

main! = |_args| {
    print_greeting!("Alice")
    print_greeting!("Bob")

    result = add_and_double(5, 7)
    echo!("add_and_double(5, 7) = ${result.to_str()}\n")

    echo!("${describe_number(9)}\n")

    Ok({})
}
