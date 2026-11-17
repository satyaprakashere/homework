use std::fmt::Debug;

// A generic function with multiple trait bounds.
// print_and_return : T Debug Clone => T -> T
fn print_and_return<T>(val: T) -> T where T: Debug + Clone {
    println!("Processing: {:?}", val);

    val.clone()
}

// A trait with an associated type and a default implementation.
trait Processor {
    type Output;

    fn process(&self) -> Self::Output;
    fn describe(&self) {
        println!("This is a processor.");
    }
}

struct StringProcessor(String);

impl Processor for StringProcessor {
    type Output = usize;
    fn process(&self) -> Self::Output {
        self.0.len()
    }
}

pub fn run_generics_demo() {
    println!("\n--- 1. Generics & Traits Demo ---");
    let x = print_and_return(vec![1, 2, 3]);
    println!("Returned: {:?}", x);

    let p = StringProcessor("Hello Rust".to_string());
    p.describe();
    println!("Processed length: {}", p.process());
}
