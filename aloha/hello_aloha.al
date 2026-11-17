// Welcome to Aloha (Rust--)!
// Pure iron performance, zero lifetime friction.
// 100% valid standard Rust syntax, directly compilable by rustc and cargo.

pub struct Vector2 {
    pub x: f64,
    pub y: f64,
}

pub fn add_vectors(a: &Vector2, b: &Vector2) -> Vector2 {
    Vector2 {
        x: a.x + b.x,
        y: a.y + b.y,
    }
}

fn main() {
    let v1 = Vector2 { x: 10.0, y: 20.0 };
    let v2 = Vector2 { x: 5.0, y: 15.0 };
    let v3 = add_vectors(&v1, &v2);

    println!("--- Aloha Vector Addition ---");
    println!("Vector 1: ({}, {})", v1.x, v1.y);
    println!("Vector 2: ({}, {})", v2.x, v2.y);
    println!("Vector Sum: ({}, {})", v3.x, v3.y);
}
