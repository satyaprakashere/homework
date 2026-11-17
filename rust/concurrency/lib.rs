//! Fearless Concurrency in Rust
//!
//! Complete suite of practical examples and patterns demonstrating Rust's
//! compile-time data race prevention and modern concurrency primitives.

//pub mod arc_mutex;
//pub mod atomics;
//pub mod bounded_channels;
//pub mod channels_mpsc;
//pub mod condvar_barrier;
//pub mod parallel_pipeline;
//pub mod rwlock;
//pub mod scoped_threads;
//pub mod send_sync_traits;
//pub mod thread_pool;
//pub mod threads_and_move;

//pub use thread_pool::ThreadPool;

/// Utility function to print a clean banner for console demonstrations
pub fn print_section(title: &str) {
    println!("\n{}", "=".repeat(60));
    println!("  {}", title);
    println!("{}\n", "=".repeat(60));
}
