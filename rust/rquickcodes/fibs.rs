type Num = u64;

fn fib(n: u64) -> Num {
    fib_helper(n, 0, 1)
}

fn fib_helper(n: u64, a: Num, b: Num) -> Num {
    match n {
        0 => a,
        _ => fib_helper(n - 1, b, a.wrapping_add(b)),
    }
}

fn main() {
    println!("{}", fib(987654321));
}
