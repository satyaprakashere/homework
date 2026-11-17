// A friendly first program in Goose.
//
// Goose is a memory-safe systems programming language designed without
// a heap allocator, garbage collector, or manual lifetime annotations.
//
// Run this directly:
//   goose hello_world.goose
// Or compile to an executable:
//   goose build hello_world.goose && ./hello_world

fn greet(name: u8[:]) {
    print("Hello, ", name, "! Welcome to Goose lang.");
}

fn add(a: i64, b: i64) -> i64 {
    return a + b;
}

fn main() {
    print("========================================");
    print("       Welcome to Goose Language!       ");
    print("========================================");

    // Call a function passing a string slice
    greet("learner");

    // Basic scalar values and types
    let a: i64 = 10;
    let b: i64 = 32;
    let sum = add(a, b);
    print("add(10, 32) = ", sum);

    // Basic arrays and iteration
    let numbers: i32[4] = [1, 2, 3, 4];
    print("Here are some numbers in a fixed array:");
    for n in numbers {
        print("  number: ", n);
    }

    print("\nGoose is ready! Check out tour.goose for a deep dive.");
}
