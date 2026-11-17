#[allow(warnings)]
mod bindings {
    wit_bindgen::generate!({
        path: "../wit",
        world: "runner",
    });
}

use bindings::example::calculator::engine_api;
use bindings::example::calculator::types::{ComputeRequest, Operation};

fn main() {
    println!("🦀 [Rust Runner] Initializing WASM Component...");

    // 1. Test basic calculations
    let test_cases = vec![
        ("Addition (500.25 + 250.75)", Operation::Add, 500.25, 250.75),
        ("Multiplication (16.0 * 4.5)", Operation::Multiply, 16.0, 4.5),
        ("Subtraction (1000.0 - 333.33)", Operation::Subtract, 1000.0, 333.33),
        ("Division (99.0 / 3.0)", Operation::Divide, 99.0, 3.0),
        ("Division by zero (10.0 / 0.0)", Operation::Divide, 10.0, 0.0),
    ];

    for (name, op, a, b) in test_cases {
        let req = ComputeRequest { op, a, b };
        match engine_api::calculate(req) {
            Ok(result) => println!("   {} -> Result: {:.2}", name, result),
            Err(err) => println!("   {} -> Handled Error: {}", name, err),
        }
    }

    // 2. Test statistical analysis on slice
    let numbers = vec![100.5, 200.0, 350.75, 50.25, 420.0, 80.0];
    match engine_api::compute_stats(&numbers) {
        Ok(stats) => {
            // 3. Test report formatting
            let report = engine_api::format_report("Sensor Array Readings", stats);
            println!("\n{}", report);
        }
        Err(err) => {
            eprintln!("   Failed to compute stats: {}", err);
        }
    }

    println!("\n✅ [Rust Runner] Completed communication with Engine successfully!");
}
