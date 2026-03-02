type Num = u64;

fn fib(n: u64) -> Num {
    fn fib_helper(n: u64, a: Num, b: Num) -> Num {
        if n == 0 {
            return a
        }
        fib_helper(n - 1, b, a.wrapping_add(b))
    }
    fib_helper(n, 0, 1)
}

fn main() {
    println!("{}", fib(98765));
}
