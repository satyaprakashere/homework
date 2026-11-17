//use concurrency::*;

mod lib;
mod rwlock;
mod atomics;
mod arc_mutex;
mod thread_pool;
mod channels_mpsc;
mod scoped_threads;
mod condvar_barrier;
mod threads_and_move;
mod send_sync_traits;
mod bounded_channels;
mod parallel_pipeline;

use lib::print_section;
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() > 1 {
        let topic = args[1].to_lowercase();
        match topic.as_str() {
            "threads_and_move" | "threads" => threads_and_move::run(),
            "scoped_threads" | "scoped" => scoped_threads::run(),
            "channels_mpsc" | "mpsc" | "channels" => channels_mpsc::run(),
            "bounded_channels" | "bounded" => bounded_channels::run(),
            "arc_mutex" | "mutex" => arc_mutex::run(),
            "rwlock" => rwlock::run(),
            "atomics" | "atomic" => atomics::run(),
            "condvar_barrier" | "condvar" | "barrier" => condvar_barrier::run(),
            "send_sync_traits" | "send_sync" | "traits" => send_sync_traits::run(),
            "thread_pool" | "pool" => thread_pool::run(),
            "parallel_pipeline" | "pipeline" => parallel_pipeline::run(),
            "all" => run_all(),
            "help" | "--help" | "-h" => print_usage(),
            unknown => {
                eprintln!("Unknown topic: '{}'", unknown);
                print_usage();
            }
        }
        return;
    }

    // Default: run full guided tour of all fearless concurrency topics
    run_all();
}

fn print_usage() {
    println!("Usage: cargo run [TOPIC]");
    println!("\nAvailable topics:");
    println!("  threads_and_move   - Thread spawning, move closures, and ThreadBuilder");
    println!("  scoped_threads     - std::thread::scope and safe stack borrowing");
    println!("  channels_mpsc      - Message passing and ownership transfer with mpsc");
    println!("  bounded_channels   - sync_channel, backpressure, and rendezvous");
    println!("  arc_mutex          - Shared-state concurrency with Arc<Mutex<T>>");
    println!("  rwlock             - Concurrent readers & exclusive writer with RwLock");
    println!("  atomics            - Lock-free synchronization, CAS, and memory orderings");
    println!("  condvar_barrier    - Condvar signaling, Barrier rendezvous, OnceLock");
    println!("  send_sync_traits   - The Send & Sync marker traits and compile-time safety");
    println!("  thread_pool        - Custom worker thread pool with graceful shutdown");
    println!("  parallel_pipeline  - Multi-stage parallel producer-consumer pipeline");
    println!("  all                - Run all demonstrations sequentially (default)");
}

fn run_all() {
    println!("============================================================");
    println!("       FEARLESS CONCURRENCY IN RUST: COMPLETE TOUR          ");
    println!("============================================================");

    print_section("TOPIC 1: Threads and Move Closures");
    threads_and_move::run();

    print_section("TOPIC 2: Scoped Threads (std::thread::scope)");
    scoped_threads::run();

    print_section("TOPIC 3: Message Passing with Channels (mpsc)");
    channels_mpsc::run();

    print_section("TOPIC 4: Bounded Channels & Backpressure");
    bounded_channels::run();

    print_section("TOPIC 5: Shared Mutable State (Arc<Mutex<T>>)");
    arc_mutex::run();

    print_section("TOPIC 6: Reader-Writer Locks (Arc<RwLock<T>>)");
    rwlock::run();

    print_section("TOPIC 7: Lock-Free Synchronization with Atomics");
    atomics::run();

    print_section("TOPIC 8: Coordination Primitives (Condvar, Barrier, OnceLock)");
    condvar_barrier::run();

    print_section("TOPIC 9: The Foundation: Send & Sync Marker Traits");
    send_sync_traits::run();

    print_section("TOPIC 10: Worker ThreadPool Pattern");
    thread_pool::run();

    print_section("TOPIC 11: Multi-Stage Streaming Pipeline");
    parallel_pipeline::run();

    println!("\n============================================================");
    println!("       ALL FEARLESS CONCURRENCY DEMOS FINISHED!             ");
    println!("============================================================\n");
}
