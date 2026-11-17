#[derive(Debug)]
pub enum AppError {
    NotFound(String),
    PermissionDenied,
    Unknown,
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AppError::NotFound(msg)     => write!(f, "Not Found: {}", msg),
            AppError::PermissionDenied  => write!(f, "Permission Denied"),
            AppError::Unknown           => write!(f, "An unknown error occurred"),
        }
    }
}

impl std::error::Error for AppError {}

fn risky_operation() -> Result<(), AppError> {
    Err(AppError::NotFound("User session".to_string()))
}

pub fn run_error_demo() {
    println!("\n--- 3. Custom Error Types ---");
    match risky_operation() {
        Ok(_)   => println!("Success!"),
        Err(e)  => {
            println!("Caught error: {}", e);
            if let AppError::NotFound(_) = e {
                println!("Specific handling for NotFound error.");
            }
        }
    }
}
