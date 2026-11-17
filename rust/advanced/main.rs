mod generics;
mod concurrency;
mod errors;

fn main() {
    println!("=== Rust Advanced Learning Lab ===");
    
    generics::run_generics_demo();

    concurrency::run_concurrency_demo();
    
    errors::run_error_demo();
    
    println!("\n=== Lab Complete ===");
}
