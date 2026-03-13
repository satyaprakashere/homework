use wgpu;

fn main() {
    println!("Hello, world!");

    wgpu::init();
    test_array();
}

fn test_array() {
    let arr1 = [1, 2, 4];
    println!("{:?}", arr1);
}
