# Fearless Concurrency in Rust

A complete, production-grade guide and runnable code suite demonstrating Rust's **Fearless Concurrency** primitives and idioms from the modern standard library.

Rust's ownership model and type system (`Send` and `Sync`) guarantee at compile time that multi-threaded code is free of data races.

---

## Directory Structure

All source files are located directly within the `src/` directory (with no numbering):

```
concurrency/
├── Cargo.toml
├── README.md
└── src/
    ├── main.rs               # Interactive / topic-based CLI runner
    ├── lib.rs                # Library exporting all concurrency modules
    ├── threads_and_move.rs   # thread::spawn, JoinHandle, move closures, ThreadBuilder
    ├── scoped_threads.rs     # std::thread::scope, borrowing stack data safely without Arc
    ├── channels_mpsc.rs      # Message passing, ownership transfer, multiple producers
    ├── bounded_channels.rs   # sync_channel, backpressure, zero-capacity rendezvous
    ├── arc_mutex.rs          # Shared mutable state with Arc<Mutex<T>>, poison recovery
    ├── rwlock.rs             # Multiple concurrent readers XOR exclusive writer
    ├── atomics.rs            # Lock-free synchronization, CAS loop, memory orderings
    ├── condvar_barrier.rs    # Condvar signaling, Barrier rendezvous, OnceLock singleton
    ├── send_sync_traits.rs   # The foundation: Send & Sync marker traits
    ├── thread_pool.rs        # Production worker ThreadPool with graceful shutdown
    └── parallel_pipeline.rs  # Multi-stage producer-consumer streaming data pipeline
```

---

## Running the Examples

### 1. Run the Full Guided Tour
To run all examples sequentially:
```bash
cargo run
# or explicitly:
cargo run -- all
```

### 2. Run an Individual Topic
You can run any specific topic by passing its name:
```bash
cargo run -- threads_and_move
cargo run -- scoped_threads
cargo run -- channels_mpsc
cargo run -- bounded_channels
cargo run -- arc_mutex
cargo run -- rwlock
cargo run -- atomics
cargo run -- condvar_barrier
cargo run -- send_sync_traits
cargo run -- thread_pool
cargo run -- parallel_pipeline
```

### 3. Run Unit Tests
```bash
cargo test
```

---

## Summary of Topics

### 1. [threads_and_move.rs](src/threads_and_move.rs)
- **`std::thread::spawn` & `JoinHandle`**: Spawning OS threads and synchronizing their completion.
- **`move` Closures**: Rust enforces moving environment variables into threads, preventing dangling stack references and use-after-free at compile time.
- **Panic Isolation**: Panics in child threads are contained and can be inspected via `.join()`.
- **`std::thread::Builder`**: Setting custom thread names and stack sizes.

### 2. [scoped_threads.rs](src/scoped_threads.rs)
- **`std::thread::scope`**: Modern Rust (1.63+) scoped concurrency.
- **Safe Stack Borrowing**: Because the compiler guarantees all scoped threads finish before the scope exits, threads can borrow local stack variables (`&T`) without `Arc` overhead.
- **Disjoint Mutable Slices**: Mutating non-overlapping slices in parallel using `split_at_mut`.

### 3. [channels_mpsc.rs](src/channels_mpsc.rs)
- **Ownership Transfer**: Sending a value over `mpsc::channel()` transfers ownership. The sender can no longer access or mutate the data, preventing data races.
- **Multiple Producers**: Cloning the sender (`tx.clone()`) to allow multiple workers to feed into a single consumer.

### 4. [bounded_channels.rs](src/bounded_channels.rs)
- **`mpsc::sync_channel(bound)`**: Synchronous channels that provide backpressure when the buffer is full.
- **Rendezvous Synchronization**: Bounded channels with capacity `0` where sending blocks until a receiver is ready to take the item.
- **Non-blocking APIs**: `try_send` and `try_recv` to prevent thread blocking.

### 5. [arc_mutex.rs](src/arc_mutex.rs)
- **`Arc<Mutex<T>>`**: Atomic reference counting combined with mutual exclusion.
- **Lock Poisoning**: If a thread panics while holding a mutex, the lock becomes poisoned so subsequent threads are alerted to potential invariant violations. Demonstrates how to recover cleanly with `.into_inner()`.
- **Deadlock Avoidance**: Non-blocking `try_lock()` and consistent lock acquisition ordering.

### 6. [rwlock.rs](src/rwlock.rs)
- **`Arc<RwLock<T>>`**: Allows multiple readers *or* a single exclusive writer. Ideal for read-heavy workloads (e.g., caches, configuration).

### 7. [atomics.rs](src/atomics.rs)
- **Lock-Free Primitives**: `AtomicBool`, `AtomicUsize`.
- **Atomic Read-Modify-Write**: `fetch_add`, `fetch_sub`, `swap`.
- **CAS (Compare-and-Swap)**: `compare_exchange` and `compare_exchange_weak` for lock-free state transitions.
- **Memory Orderings**: `Relaxed`, `Acquire`, `Release`, and `SeqCst`.

### 8. [condvar_barrier.rs](src/condvar_barrier.rs)
- **`Condvar`**: Condition variables to put threads to sleep until notified by another thread. Uses `wait_while` to handle spurious wakeups.
- **`Barrier`**: Synchronizes a group of threads to wait until all threads have reached a rendezvous point before proceeding.
- **`OnceLock`**: Standard library primitive for thread-safe lazy one-time initialization.

### 9. [send_sync_traits.rs](src/send_sync_traits.rs)
- **`Send`**: Types whose ownership can be transferred across thread boundaries.
- **`Sync`**: Types safe to share between threads via shared reference (`&T`).
- **Compile-Time Guarantees**: Why `Rc` is `!Send` and `!Sync` while `Arc` is `Send + Sync`. Why `RefCell` is `Send` but `!Sync`.

### 10. [thread_pool.rs](src/thread_pool.rs)
- **Worker Thread Pool**: Reusable pool dispatching boxed closures across worker threads.
- **Graceful Shutdown**: Draining tasks, signaling workers via channel disconnection on `Drop`, and joining all worker threads.

### 11. [parallel_pipeline.rs](src/parallel_pipeline.rs)
- **Multi-Stage Pipeline**: Producer $\to$ Transformer/Filter $\to$ Aggregator.
- Demonstrates streaming data architectures with lock-free handoffs and graceful EOF termination.
