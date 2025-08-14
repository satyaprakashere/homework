use tailcall::tailcall;

pub fn fib(n: u64) -> u128 {
    fib_helper(n, 0, 1)
}

#[tailcall]
fn fib_helper(n: u64, a: u128, b: u128) -> u128 {
    match n {
        0 => a,
        _ => fib_helper(n - 1, b, a.wrapping_add(b)),
    }
}
