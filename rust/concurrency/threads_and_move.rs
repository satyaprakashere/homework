use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Basic Thread Spawning & JoinHandle ===");
    let handle = thread::spawn(|| {
        for i in 1..=4 {
            println!("   [Spawned thread] counting: {}", i);
            thread::sleep(Duration::from_millis(30));
        }
        "Work completed successfully!"
    });

    for i in 1..=2 {
        println!("[Main thread] working concurrently: {}", i);
        thread::sleep(Duration::from_millis(40));
    }

    // Join ensures the main thread waits for the spawned thread to finish.
    let result = handle.join().expect("Failed to join thread");
    println!("Spawned thread returned: \"{}\"", result);

    println!("\n=== 2. The `move` Closure & Ownership Guarantees ===");
    // Without `move`, the closure would attempt to borrow `data`.
    // Because the spawned thread might outlive the current function, the Rust compiler
    // forbids borrowing stack variables across thread::spawn (which requires 'static).
    // The `move` keyword transfers ownership of `data` directly into the thread!
    let data = vec![10, 20, 30, 40, 50];
    let consumer = thread::spawn(move || {
        println!("   [Consumer thread] Owned data sum: {}", data.iter().sum::<i32>());
        // `data` will be cleanly dropped here when the thread terminates.
    });
    consumer.join().unwrap();
    // println!("{:?}", data); // COMPILE ERROR! Rust prevents using `data` here because it was moved!

    println!("\n=== 3. Graceful Panic Handling ===");
    let risky_worker = thread::spawn(|| {
        println!("   [Risky thread] Doing risky calculation...");
        panic!("Something went wrong inside the thread!");
    });

    match risky_worker.join() {
        Ok(_) => println!("Thread completed without error"),
        Err(err) => {
            if let Some(msg) = err.downcast_ref::<&str>() {
                println!("Caught thread panic safely in main: \"{}\"", msg);
            } else {
                println!("Caught thread panic safely in main");
            }
        }
    }
    println!("Main thread continues running unharmed!");

    println!("\n=== 4. Custom Thread Configuration with ThreadBuilder ===");
    let custom_thread = thread::Builder::new()
        .name("background-worker".to_string())
        .stack_size(4 * 1024 * 1024) // 4 MB stack
        .spawn(|| {
            let current = thread::current();
            println!(
                "   Running in custom thread: name = {:?}, id = {:?}",
                current.name(),
                current.id()
            );
        })
        .expect("Failed to spawn custom thread");

    custom_thread.join().unwrap();
    println!("\n[threads_and_move] Completed successfully!\n");
}
