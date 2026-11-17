# variables_and_strings.roc
# Run with: roc variables_and_strings.roc
#
# Topics: constants, string interpolation, Str functions

main! = |_args| {
    # --- Constants ---
    # All values in Roc are immutable constants by default.
    name = "Rocco"
    language = "Roc"
    year = 2026

    # --- String Interpolation ---
    # Use ${expression} inside a string to embed values.
    # Interpolated expressions must evaluate to a String.
    echo!("Hello, ${name}! Welcome to ${language}.\n")

    # To embed a number, convert it first with .to_str()
    echo!("Current year: ${year.to_str()}\n")

    # Expressions inside interpolation
    a = 10
    b = 3
    echo!("${a.to_str()} + ${b.to_str()} = ${(a + b).to_str()}\n")

    # Str functions
    greeting = Str.concat("Hello, ", name)
    echo!("Concat: ${greeting}\n")

    # String length in bytes
    byte_len = Str.count_utf8_bytes(name)
    echo!("'${name}' has ${byte_len.to_str()} bytes\n")

    Ok({})
}
