use std::io;

fn main() {
    let x:u8 = 255;
    let mut input = String::new();

    std::io::stdin().read_line(&mut input);
    let y:u8 = input.parse::<u8>().unwrap_or(10);

    let z = x + y;
    println!("Hello, world!");
    println!("The sum is {}", z);
}
