//! Example: The Foundation of Fearless Concurrency (Send and Sync Traits)
//!
//! Demonstrates:
//! 1. The `Send` trait: ownership transfer across thread boundaries
//! 2. The `Sync` trait: safe shared references (&T) across thread boundaries
//! 3. Why `Rc<T>` is !Send and !Sync while `Arc<T>` is Send + Sync
//! 4. Why `RefCell<T>` is Send but !Sync
//! 5. How the Rust compiler enforces thread safety at compile time with zero runtime cost

use std::cell::RefCell;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;

// Compile-time static assertions for Send and Sync
fn assert_send<T: Send>() {}
fn assert_sync<T: Sync>() {}

// A struct where all fields are Send + Sync is automatically Send + Sync:
#[derive(Debug)]
struct UserProfile {
    id: u64,
    name: String,
    visits: AtomicUsize,
}

// A custom wrapper demonstrating how raw pointers opt-out of Send/Sync,
// and how `unsafe impl Send` / `unsafe impl Sync` can be implemented when invariants are upheld.
struct ThreadSafeBuffer {
    data: Vec<u8>,
}

unsafe impl Send for ThreadSafeBuffer {}
unsafe impl Sync for ThreadSafeBuffer {}

pub fn run() {
    println!("=== 1. Compile-Time Trait Verification ===");
    // These compile cleanly because the types satisfy the traits:
    assert_send::<i32>();
    assert_sync::<i32>();

    assert_send::<String>();
    assert_sync::<String>();

    assert_send::<Arc<Mutex<i32>>>();
    assert_sync::<Arc<Mutex<i32>>>();

    assert_send::<UserProfile>();
    assert_sync::<UserProfile>();

    // RefCell is Send (can be moved to another thread) but !Sync (cannot be shared via &RefCell)
    assert_send::<RefCell<i32>>();
    // assert_sync::<RefCell<i32>>(); // COMPILE ERROR if uncommented!

    // Rc is neither Send nor Sync because its reference count is not atomic
    // assert_send::<Rc<i32>>(); // COMPILE ERROR if uncommented!
    // assert_sync::<Rc<i32>>(); // COMPILE ERROR if uncommented!

    println!("   Static assertions passed! The compiler verified thread safety.");

    println!("\n=== 2. Why Rc fails across threads & Arc succeeds ===");
    println!("   Rc<T> uses non-atomic increments. If sent to another thread,");
    println!("   cloning it simultaneously would cause a data race on the ref count.");
    println!("   Rust's borrow checker rejects thread::spawn(move || {{ let _ = rc.clone(); }})");
    println!("   Arc<T> uses atomic instructions, satisfying Send + Sync.");

    let shared_profile = Arc::new(UserProfile {
        id: 42,
        name: "Alice in Concurrencyland".to_string(),
        visits: AtomicUsize::new(0),
    });

    let mut handles = vec![];
    for _ in 0..4 {
        let p = Arc::clone(&shared_profile);
        handles.push(thread::spawn(move || {
            p.visits.fetch_add(1, Ordering::SeqCst);
        }));
    }

    for h in handles {
        h.join().unwrap();
    }

    println!(
        "Shared profile for '{}' (ID: {}), visits after 4 threads: {}",
        shared_profile.name,
        shared_profile.id,
        shared_profile.visits.load(Ordering::SeqCst)
    );

    println!("\n=== 3. Custom Thread-Safe Types ===");
    let buffer = Arc::new(ThreadSafeBuffer {
        data: vec![0xDE, 0xAD, 0xBE, 0xEF],
    });

    let buf_clone = Arc::clone(&buffer);
    let reader = thread::spawn(move || {
        println!("   [Worker Thread] Read buffer byte length: {}", buf_clone.data.len());
    });
    reader.join().unwrap();

    println!("\n[send_sync_traits] Completed successfully!\n");
}
