use std::fs;
use std::path::Path;
use syn::visit::{self, Visit};
use syn::Type;
use walkdir::WalkDir;

struct GuardrailVisitor {
    has_error: bool,
    current_file: String,
    error_message: String,
}

impl<'ast> Visit<'ast> for GuardrailVisitor {
    fn visit_type(&mut self, node: &'ast Type) {
        match node {
            Type::Reference(ty_ref) => {
                if ty_ref.mutability.is_some() {
                    self.has_error = true;
                    self.error_message = format!(
                        "\n❌ [rust-- violation] File: {}\n   -> Mutable references (&mut T) are strictly banned.",
                        self.current_file
                    );
                }
                if ty_ref.lifetime.is_some() {
                    self.has_error = true;
                    self.error_message = format!(
                        "\n❌ [rust-- violation] File: {}\n   -> Lifetime annotations ('a) are strictly banned.",
                        self.current_file
                    );
                }
            }
            _ => {}
        }
        visit::visit_type(self, node);
    }
}

fn main() {
    // Tell Cargo to re-run this build script if any source file changes
    println!("cargo:rerun-if-changed=src/");

    let mut visitor = GuardrailVisitor {
        has_error: false,
        current_file: String::new(),
        error_message: String::new(),
    };

    let src_dir = Path::new("src");
    if src_dir.exists() {
        for entry in WalkDir::new(src_dir).into_iter().filter_map(|e| e.ok()) {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("rs") {
                visitor.current_file = path.display().to_string();
                let content = fs::read_to_string(path).unwrap_or_default();
                
                if let Ok(syntax_tree) = syn::parse_file(&content) {
                    visitor.visit_file(&syntax_tree);
                }

                if visitor.has_error {
                    eprintln!("{}", visitor.error_message);
                    std::process::exit(1); // Halts cargo build immediately with a hard error
                }
            }
        }
    }
}
