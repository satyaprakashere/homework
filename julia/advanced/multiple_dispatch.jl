function greet(x:: Int)
    println("Hello, integer $x")
end

function greet(x:: String)
    println("Hello, string $x")
end

function run_demo()
    println("\n--- 1. Julia Multiple Dispatch Demo ---")
    greet(42)
    greet("world")
end

run_demo()
