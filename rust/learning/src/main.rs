mod tailcall;

fn main() {
    println!("Hello, world!");
    println!("{}", tailcall::fib(987654321));
}
