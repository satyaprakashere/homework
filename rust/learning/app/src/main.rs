mod maths;

// Bring the custom attribute macro into scope
//use guardrail::rust_minus;

mod app_code {
    pub struct Point {
        pub x: i32,
        pub y: i32,
    }
    
    // ✅ Valid: Immutable reference, local mutation, zero lifetimes
    pub fn compute(p: &Point) -> i32 {
        let mut total = 10;
        total += p.x + p.y;
        total
    }
    
    // ❌ If you uncommented this, cargo build would instantly throw a hard error:
//  pub fn illegal(p: &mut Point) { p.x = 0; }
}

//#[rust_minus]
fn main() {
    println!("Hello, world!");
    println!("{}", maths::fib(98765432));
}
