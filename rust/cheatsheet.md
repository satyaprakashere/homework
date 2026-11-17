# Rust Learning Cheat Sheet 🦀

## 🛠 Essential Commands

| Command | Description |
| :--- | :--- |
| `cargo new <name>` | Create a new project. |
| `cargo run` | Build and run. |
| `cargo check` | Check for errors without building. |
| `cargo test` | Run tests. |
| `cargo add <crate>` | Add a dependency to Cargo.toml. |

## 🏗 Language Features

### Basic Features
- **Ownership**: Values have a single owner.
- **Borrowing**: Immutable (`&T`) and Mutable (`&mut T`) references.
- **Enums & Pattern Matching**: Powerful `match` expressions.
- **Structs**: Data structures (`struct User { ... }`).
- **Options & Results**: Safe handling of nulls and errors.

### Advanced Features
- **[Traits](file:///Users/prakash/Documents/homework/rust/advanced/generics.rs)**: Defining shared behavior (polymorphism).
- **[Generics](file:///Users/prakash/Documents/homework/rust/advanced/generics.rs)**: Reusable components with trait bounds.
- **[Concurrency](file:///Users/prakash/Documents/homework/rust/advanced/concurrency.rs)**: Safe data sharing with `Arc` and `Mutex`.
- **[Error Handling](file:///Users/prakash/Documents/homework/rust/advanced/errors.rs)**: Custom `error` types and `Result` wrapping.
- **Lifetimes**: Ensuring references are valid as long as needed.
- **Macros**: Metaprogramming with `macro_rules!` or procedural macros.

## 💡 Quick Tips

### 1. The Borrow Checker
The compiler ensures memory safety by enforcing ownership rules at compile-time.

### 2. Pattern Matching
```rust
match option {
    Some(x) => println!("Got {}", x),
    None => println!("Nothing"),
}
```

### 3. Cargo.toml
All dependencies and metadata are managed in this file.
