//! Example: Reader-Writer Lock (std::sync::RwLock)
//!
//! Demonstrates:
//! 1. `Arc<RwLock<T>>` for read-heavy shared data
//! 2. Multiple concurrent readers reading simultaneously without blocking each other
//! 3. Single exclusive writer with guaranteed isolation
//! 4. Why RwLock out-performs Mutex in read-heavy workloads

use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Concurrent Readers + Exclusive Writer ===");
    let mut initial_cache = HashMap::new();
    initial_cache.insert("user:101", "Alice");
    initial_cache.insert("user:102", "Bob");

    let cache = Arc::new(RwLock::new(initial_cache));
    let mut reader_handles = vec![];

    // Spawn 5 concurrent readers
    for reader_id in 1..=5 {
        let cache_clone = Arc::clone(&cache);
        let handle = thread::spawn(move || {
            // Multiple threads can hold a read lock at the exact same time!
            let r_guard = cache_clone.read().unwrap();
            let alice = r_guard.get("user:101").unwrap_or(&"unknown");
            println!(
                "   [Reader {}] Read user:101 => {} (concurrent read active)",
                reader_id, alice
            );
            thread::sleep(Duration::from_millis(30));
        });
        reader_handles.push(handle);
    }

    // Spawn 1 writer thread
    let writer_cache = Arc::clone(&cache);
    let writer_handle = thread::spawn(move || {
        thread::sleep(Duration::from_millis(15));
        println!("\n   >>> [Writer] Requesting exclusive write access...");
        // write() blocks until all active read locks are released!
        let mut w_guard = writer_cache.write().unwrap();
        println!("   >>> [Writer] Acquired exclusive write lock! Updating cache...");
        w_guard.insert("user:103", "Charlie");
        w_guard.insert("user:101", "Alice (Updated)");
        thread::sleep(Duration::from_millis(40));
        println!("   >>> [Writer] Finished update. Releasing lock.\n");
    });

    for handle in reader_handles {
        handle.join().unwrap();
    }
    writer_handle.join().unwrap();

    // Verify updated state
    {
        let final_guard = cache.read().unwrap();
        println!("Final Cache Contents:");
        for (k, v) in final_guard.iter() {
            println!("   - {}: {}", k, v);
        }
    }

    println!("\n[rwlock] Completed successfully!\n");
}
