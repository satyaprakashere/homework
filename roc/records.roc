# records.roc
# Run with: roc records.roc
# Run tests with: roc test records.roc
#
# Topics: record literals, field access, records in functions,
#         nested records
#
# Note: Booleans are `True`/`False` (not Bool.true/Bool.false)
# Note: Record destructuring in function args requires the type to be known

# --- Record literals ---
alice = { name: "Alice", age: 30, active: True }
bob   = { name: "Bob",   age: 25, active: False }

expect alice.name == "Alice"
expect alice.age == 30
expect bob.active == False

# --- Functions that take records ---
greet_user = |user| "Hello, ${user.name}! You are ${user.age.to_str()} years old."

expect greet_user(alice) == "Hello, Alice! You are 30 years old."

# --- "Updating" a record: construct a new one explicitly ---
birthday = |user| { name: user.name, age: user.age + 1, active: user.active }

older_alice = birthday(alice)
expect older_alice.name == "Alice"
expect older_alice.age  == 31
expect alice.age        == 30        # original untouched

# --- Destructuring via field access ---
# (Full destructuring in function args has type inference limitations)
describe = |user| "${user.name} is ${user.age.to_str()}"

expect describe(alice) == "Alice is 30"

# --- Nested records ---
point_a = { x: 3, y: 4 }
point_b = { x: 7, y: 8 }
line    = { start: point_a, end: point_b }

expect line.start.x == 3
expect line.end.y == 8

sq_dist = |p1, p2| {
    dx = p2.x - p1.x
    dy = p2.y - p1.y
    dx * dx + dy * dy
}

expect sq_dist(point_a, point_b) == 32

main! = |_args| {
    echo!("${greet_user(alice)}\n")
    echo!("${greet_user(bob)}\n")
    echo!("After birthday: ${greet_user(older_alice)}\n")
    echo!("${describe({ name: "Charlie", age: 22, active: True })}\n")
    echo!("Squared distance: ${sq_dist(point_a, point_b).to_str()}\n")

    Ok({})
}
