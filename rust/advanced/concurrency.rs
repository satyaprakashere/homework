use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

pub fn run_concurrency_demo() {
    println!("\n--- 2. Advanced Concurrency (Arc + Mutex) ---");

    // Arc (Atomic Reference Counted) allows multiple ownership across threads.
    // Mutex (Mutual Exclusion) allows safe mutation across threads.
    let counter     = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for i in 0..5 {
        let counter = Arc::clone(&counter);
        let handle  = thread::spawn(move || {
            let mut num = counter.lock().unwrap();
            *num += 1;
            println!("Thread {} incremented counter to {}", i, *num);
            thread::sleep(Duration::from_millis(50));
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Final counter value: {}", *counter.lock().unwrap());
}
