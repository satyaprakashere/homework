//! Example: Lock-Free Synchronization with Atomics
//!
//! Demonstrates:
//! 1. `AtomicBool`, `AtomicUsize`, `AtomicI64`
//! 2. Atomic read-modify-write: `fetch_add`, `fetch_sub`, `swap`
//! 3. Lock-free cancellation flag (`store` and `load`)
//! 4. Compare-and-swap (CAS) loop with `compare_exchange`
//! 5. Memory orderings: `Relaxed`, `Acquire`, `Release`, `SeqCst`

use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Lock-Free Atomic Counter (fetch_add) ===");
    // Atomics use CPU hardware instructions directly (e.g. LOCK XADD on x86, LDREX/STREX on ARM)
    // without operating system mutexes or context switches.
    let counter = Arc::new(AtomicUsize::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter_clone = Arc::clone(&counter);
        let handle = thread::spawn(move || {
            for _ in 0..1000 {
                // Ordering::Relaxed guarantees atomicity of this single variable without synchronizing
                // memory with other variables.
                counter_clone.fetch_add(1, Ordering::Relaxed);
            }
        });
        handles.push(handle);
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!(
        "Final atomic counter value (10 threads * 1000 increments): {}",
        counter.load(Ordering::SeqCst)
    );

    println!("\n=== 2. Atomic Cancellation Flag (AtomicBool) ===");
    let running = Arc::new(AtomicBool::new(true));
    let running_clone = Arc::clone(&running);

    let background_worker = thread::spawn(move || {
        let mut ticks = 0;
        // Acquire ordering ensures subsequent memory reads see all writes that preceded Release
        while running_clone.load(Ordering::Acquire) {
            ticks += 1;
            thread::sleep(Duration::from_millis(15));
        }
        println!("   [Worker] Cancellation signal observed after {} ticks. Shutting down.", ticks);
    });

    thread::sleep(Duration::from_millis(60));
    println!("[Main] Sending cancellation signal via AtomicBool::store(false)...");
    // Release ordering ensures all previous writes in this thread become visible to Acquire in worker
    running.store(false, Ordering::Release);
    background_worker.join().unwrap();

    println!("\n=== 3. Compare-and-Swap (CAS) Loop ===");
    // Implement lock-free update: keeping track of maximum value seen across threads
    let max_val = Arc::new(AtomicUsize::new(0));
    let mut cas_handles = vec![];

    let test_values = vec![15, 82, 47, 99, 12, 105, 33, 76];
    for &val in &test_values {
        let max_val = Arc::clone(&max_val);
        cas_handles.push(thread::spawn(move || {
            let mut current = max_val.load(Ordering::Relaxed);
            loop {
                if val <= current {
                    // Current is already larger, no update needed
                    break;
                }
                // Attempt to swap in `val` only if `max_val` is still equal to `current`.
                // If another thread updated `max_val` in the meantime, compare_exchange returns Err(new_current),
                // and the loop retries with the new current value!
                match max_val.compare_exchange_weak(
                    current,
                    val,
                    Ordering::SeqCst,
                    Ordering::Relaxed,
                ) {
                    Ok(_) => {
                        println!("   [CAS Thread] Successfully updated max to {}", val);
                        break;
                    }
                    Err(actual) => {
                        current = actual;
                    }
                }
            }
        }));
    }

    for handle in cas_handles {
        handle.join().unwrap();
    }

    println!("Lock-free computed maximum: {}", max_val.load(Ordering::SeqCst));
    println!("\n[atomics] Completed successfully!\n");
}
