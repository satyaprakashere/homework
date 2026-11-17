//! Example: Coordination Primitives (Condvar, Barrier, OnceLock)
//!
//! Demonstrates:
//! 1. `std::sync::Condvar` (Condition Variable) for inter-thread notifications
//! 2. Handling spurious wakeups with `wait_while`
//! 3. `std::sync::Barrier` for multi-thread milestone rendezvous
//! 4. `std::sync::OnceLock` for thread-safe lazy one-time initialization

use std::sync::{Arc, Barrier, Condvar, Mutex, OnceLock};
use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Condvar: Inter-Thread Signaling ===");
    // Condvar allows threads to sleep without consuming CPU until notified of a state change
    let pair = Arc::new((Mutex::new(false), Condvar::new()));
    let pair_clone = Arc::clone(&pair);

    let worker = thread::spawn(move || {
        let (lock, cvar) = &*pair_clone;
        println!("   [Worker] Waiting on Condvar until work is ready...");

        let mut ready = lock.lock().unwrap();
        // `wait_while` handles spurious wakeups by re-checking the condition predicate!
        ready = cvar.wait_while(ready, |is_ready| !*is_ready).unwrap();

        println!("   [Worker] Received notification! Condition is now ready = {}", *ready);
    });

    thread::sleep(Duration::from_millis(60));
    println!("[Main] Preparing data and notifying worker via Condvar...");
    {
        let (lock, cvar) = &*pair;
        let mut ready = lock.lock().unwrap();
        *ready = true;
        cvar.notify_one();
    }
    worker.join().unwrap();

    println!("\n=== 2. Barrier: Synchronizing Multi-Thread Milestones ===");
    // A Barrier stops all threads until N threads have arrived at the barrier.
    const NUM_THREADS: usize = 4;
    let barrier = Arc::new(Barrier::new(NUM_THREADS));
    let mut handles = vec![];

    for id in 1..=NUM_THREADS {
        let b = Arc::clone(&barrier);
        handles.push(thread::spawn(move || {
            println!("   [Thread {}] Performing Phase 1 preparation...", id);
            thread::sleep(Duration::from_millis((id as u64) * 20));
            println!("   [Thread {}] Reached Barrier checkpoint.", id);

            // Wait for all other threads to arrive
            let wait_result = b.wait();
            if wait_result.is_leader() {
                println!("\n   >>> [Thread {} was elected LEADER] All threads arrived! Proceeding to Phase 2 <<<\n", id);
            }

            println!("   [Thread {}] Executing Phase 2 concurrently!", id);
        }));
    }

    for handle in handles {
        handle.join().unwrap();
    }

    println!("\n=== 3. OnceLock: Safe Lazy One-Time Initialization ===");
    // OnceLock is standard library feature for thread-safe global singletons
    static APP_CONFIG: OnceLock<String> = OnceLock::new();

    let mut config_handles = vec![];
    for id in 1..=5 {
        config_handles.push(thread::spawn(move || {
            let config = APP_CONFIG.get_or_init(|| {
                println!("   >>> [Thread {} initializing singleton for the FIRST and ONLY time] <<<", id);
                "DATABASE_URL=postgres://localhost:5432/app_db".to_string()
            });
            println!("   [Thread {}] Config value: \"{}\"", id, config);
        }));
    }

    for handle in config_handles {
        handle.join().unwrap();
    }

    println!("\n[condvar_barrier] Completed successfully!\n");
}
