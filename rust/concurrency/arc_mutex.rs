//! Example: Shared-State Concurrency with Arc and Mutex
//!
//! Demonstrates:
//! 1. `Arc<Mutex<T>>` for multi-threaded shared mutable state
//! 2. Mutex guards and RAII automatic unlocking
//! 3. Lock poisoning: why it happens and how to recover safely
//! 4. Non-blocking `try_lock` and avoiding deadlocks

use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Arc<Mutex<T>>: Safe Concurrent Mutation ===");
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for i in 1..=8 {
        let counter_clone = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            // lock() blocks until the mutex is acquired and returns a MutexGuard.
            // MutexGuard dereferences directly to the inner data and releases
            // the lock automatically when it goes out of scope (RAII).
            let mut num = counter_clone.lock().unwrap();
            *num += 1;
            println!("   [Thread {:02}] Incremented counter to {}", i, *num);
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("Final counter value: {}", *counter.lock().unwrap());

    println!("\n=== 2. Mutex Poisoning & Recovery ===");
    // If a thread panics while holding a MutexGuard, Rust marks the Mutex as "poisoned"
    // to alert other threads that the invariant of the protected data might be corrupted.
    let shared_state = Arc::new(Mutex::new(vec!["Initial valid state".to_string()]));

    let panicking_thread = {
        let state = Arc::clone(&shared_state);
        thread::spawn(move || {
            let mut lock = state.lock().unwrap();
            lock.push("Partial corrupted entry".to_string());
            panic!("Worker thread crashed while holding the lock!");
        })
    };

    // The thread panics, so join() returns an Err
    let _ = panicking_thread.join();

    // Now, subsequent lock() calls return Err(PoisonError):
    match shared_state.lock() {
        Ok(guard) => {
            println!("Lock acquired normally: {:?}", *guard);
        }
        Err(poisoned) => {
            println!("   Lock is POISONED! Rust protected us from silently using corrupted state.");
            // We can still inspect or recover the data if desired:
            let mut recovered_data = poisoned.into_inner();
            println!("   Recovered data from poisoned lock: {:?}", *recovered_data);
            recovered_data.push("Restored consistent state".to_string());
        }
    }

    println!("\n=== 3. Non-blocking try_lock & Deadlock Avoidance ===");
    let resource_a = Arc::new(Mutex::new("Resource A"));
    let resource_b = Arc::new(Mutex::new("Resource B"));

    let a_clone = Arc::clone(&resource_a);
    let b_clone = Arc::clone(&resource_b);

    let worker = thread::spawn(move || {
        let _guard_a = a_clone.lock().unwrap();
        thread::sleep(Duration::from_millis(50));
        let _guard_b = b_clone.lock().unwrap();
        println!("   [Worker] Acquired both Resource A and Resource B");
    });

    thread::sleep(Duration::from_millis(10));
    // Main thread tries to acquire lock without blocking indefinitely
    match resource_a.try_lock() {
        Ok(_) => println!("[Main] Acquired Resource A"),
        Err(_) => println!("[Main] Resource A is currently locked by worker; avoided blocking!"),
    }

    worker.join().unwrap();
    println!("\n[arc_mutex] Completed successfully!\n");
}
