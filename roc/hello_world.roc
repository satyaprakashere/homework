# hello_world.roc
# Run with: roc hello_world.roc
#
# This is the simplest Roc program.
# `main!` is the entry point of every Roc application.
# The `!` suffix marks it as an effectful function (one that performs side effects like printing).
# `echo!` does NOT add a newline — use \n explicitly.

main! = |_args| {
    echo!("Hello, World!\n")
    Ok({})
}
