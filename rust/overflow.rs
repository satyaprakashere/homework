use std::io;

fn main() {
    let x:u8 = 255;
    let input = String::new();
    
//  let _ = io::stdin().read_line(&mut input);
    let y = input.parse::<u8>().unwrap_or(10);

    let z = x - y;

    println!("The sum is {}", z);
    // println!("The input is {}", input.parse::<u8>());
    
//  let mut a = 123;
//  a = 56;
//  let b = &mut a;
//  a = 77;
//  println!("The a is {}", b);
}
