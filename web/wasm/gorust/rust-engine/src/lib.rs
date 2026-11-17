#[allow(warnings)]
mod bindings;

use bindings::example::calculator::types::{ComputeRequest, Operation, Stats};
use bindings::exports::example::calculator::engine_api::Guest;

struct Engine;

impl Guest for Engine {
    fn calculate(req: ComputeRequest) -> Result<f64, String> {
        match req.op {
            Operation::Add => Ok(req.a + req.b),
            Operation::Subtract => Ok(req.a - req.b),
            Operation::Multiply => Ok(req.a * req.b),
            Operation::Divide => {
                if req.b == 0.0 {
                    Err("Division by zero in Rust Engine".to_string())
                } else {
                    Ok(req.a / req.b)
                }
            }
        }
    }

    fn compute_stats(numbers: Vec<f64>) -> Result<Stats, String> {
        if numbers.is_empty() {
            return Err("Cannot compute statistics for an empty list".to_string());
        }

        let mut min = f64::INFINITY;
        let mut max = f64::NEG_INFINITY;
        let mut sum = 0.0;

        for &n in &numbers {
            if n < min {
                min = n;
            }
            if n > max {
                max = n;
            }
            sum += n;
        }

        let count = numbers.len() as u32;
        let mean = sum / (count as f64);

        Ok(Stats {
            count,
            min,
            max,
            mean,
            sum,
        })
    }

    fn format_report(title: String, data: Stats) -> String {
        format!(
            "=== [Rust Engine] {} ===\n\
             • Samples: {}\n\
             • Minimum: {:.2}\n\
             • Maximum: {:.2}\n\
             • Sum:     {:.2}\n\
             • Average: {:.2}",
            title, data.count, data.min, data.max, data.sum, data.mean
        )
    }
}

bindings::export!(Engine with_types_in bindings);
