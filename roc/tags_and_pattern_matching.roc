# tags_and_pattern_matching.roc
# Run with: roc tags_and_pattern_matching.roc
# Run tests with: roc test tags_and_pattern_matching.roc
#
# Topics: tags (sum types), match expression, Result type (Ok/Err)
#
# KEY SYNTAX: `match value { Pattern => result }`

# --- Tags with no payload (like enums) ---
color_name = |color| {
    match color {
        Red   => "red"
        Green => "green"
        Blue  => "blue"
    }
}

expect color_name(Red) == "red"
expect color_name(Blue) == "blue"

# --- Tags with payloads ---
area = |shape| {
    match shape {
        Circle(radius)   => 3 * radius * radius
        Rectangle(w, h)  => w * h
        Triangle(b, h)   => (b * h) / 2
    }
}

expect area(Circle(5)) == 75
expect area(Rectangle(4, 6)) == 24
expect area(Triangle(10, 8)) == 40

# --- Result type: Ok(value) | Err(error) ---
safe_divide = |a, b| {
    if b == 0 { Err("Division by zero") } else { Ok(a / b) }
}

expect safe_divide(10, 2) == Ok(5)
expect safe_divide(7, 0)  == Err("Division by zero")

# Unwrapping with match
describe_result = |result| {
    match result {
        Ok(v)    => "Success: ${v.to_str()}"
        Err(msg) => "Error: ${msg}"
    }
}

# Note: calling describe_result(Err("oops")) standalone is ambiguous
# because the Ok(v) branch calls v.to_str() but v's type is unknown.
# Use it on a concrete Result instead:
expect describe_result(safe_divide(10, 2)) == "Success: 5"
expect describe_result(safe_divide(10, 0)) == "Error: Division by zero"

# --- Nested tags ---
http_status = |code| {
    match code {
        200 => Ok("OK")
        201 => Ok("Created")
        404 => Err("Not Found")
        500 => Err("Internal Server Error")
        _   => Err("Unknown status")
    }
}

expect http_status(200) == Ok("OK")
expect http_status(404) == Err("Not Found")

main! = |_args| {
    echo!("Color: ${color_name(Green)}\n")

    echo!("Circle(5):      ${area(Circle(5)).to_str()}\n")
    echo!("Rectangle(4,6): ${area(Rectangle(4, 6)).to_str()}\n")
    echo!("Triangle(10,8): ${area(Triangle(10, 8)).to_str()}\n")

    echo!("10/2: ${describe_result(safe_divide(10, 2))}\n")
    echo!("10/0: ${describe_result(safe_divide(10, 0))}\n")

    echo!("HTTP 200: ${describe_result(http_status(200))}\n")
    echo!("HTTP 404: ${describe_result(http_status(404))}\n")

    Ok({})
}
