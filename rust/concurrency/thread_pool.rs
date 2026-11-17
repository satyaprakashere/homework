use std::sync::{mpsc, Arc, Mutex};
use std::thread;

/// Type alias for a boxed closure that can be sent across threads.
type Job = Box<dyn FnOnce() + Send + 'static>;

/// Worker thread representation.
struct Worker {
    _id: usize,
    thread: Option<thread::JoinHandle<()>>,
}

impl Worker {
    fn new(id: usize, receiver: Arc<Mutex<mpsc::Receiver<Job>>>) -> Worker {
        let thread = thread::Builder::new()
            .name(format!("worker-{}", id))
            .spawn(move || loop {

                let message = {
                    let rx = match receiver.lock() {
                        Ok(guard) => guard,
                        Err(poisoned) => {
                            eprintln!("Worker {} encountered poisoned mutex: {}", id, poisoned);
                            poisoned.into_inner()
                        }
                    };
                    rx.recv()
                };

                match message {
                    Ok(job) => {
                        job();
                    }
                    Err(_) => {
                        // Channel closed: sender was dropped, graceful termination signal.
                        break;
                    }
                }
            })
            .expect("Failed to spawn worker thread");

        Worker {
            _id: id,
            thread: Some(thread),
        }
    }
}

/// A ThreadPool that executes jobs concurrently across a fixed number of worker threads.
pub struct ThreadPool {
    workers: Vec<Worker>,
    sender: Option<mpsc::Sender<Job>>,
}

impl ThreadPool {
    /// Create a new ThreadPool.
    ///
    /// # Panics
    /// Panics if `size == 0`.
    pub fn new(size: usize) -> ThreadPool {
        assert!(size > 0, "ThreadPool size must be greater than zero");

        let (sender, receiver) = mpsc::channel();
        let receiver = Arc::new(Mutex::new(receiver));
        let mut workers = Vec::with_capacity(size);

        for id in 0..size {
            workers.push(Worker::new(id, Arc::clone(&receiver)));
        }

        ThreadPool {
            workers,
            sender: Some(sender),
        }
    }

    /// Execute a closure on one of the available worker threads.
    pub fn execute<F>(&self, f: F)
    where
        F: FnOnce() + Send + 'static,
    {
        let job = Box::new(f);
        if let Some(ref sender) = self.sender {
            sender.send(job).expect("Failed to send job to worker pool");
        }
    }
}

impl Drop for ThreadPool {
    fn drop(&mut self) {
        // Drop the sender to signal workers that no more jobs are coming.
        drop(self.sender.take());

        for worker in &mut self.workers {
            if let Some(thread) = worker.thread.take() {
                thread.join().expect("Worker thread failed to join cleanly");
            }
        }
    }
}

pub fn run() {
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::time::Duration;

    println!("=== Worker ThreadPool Demonstration ===");
    println!("Initializing ThreadPool with 4 worker threads...\n");

    let pool = ThreadPool::new(4);
    let completed_jobs = Arc::new(AtomicUsize::new(0));

    for job_id in 1..=8 {
        let counter = Arc::clone(&completed_jobs);
        pool.execute(move || {
            let current = thread::current();
            let thread_name = current.name().unwrap_or("unnamed");
            println!("   [{}] executing Task #{:02}...", thread_name, job_id);
            thread::sleep(Duration::from_millis(30));
            counter.fetch_add(1, Ordering::SeqCst);
            println!("   [{}] completed Task #{:02} ✓", thread_name, job_id);
        });
    }

    println!("\nAll tasks submitted to queue.");
    println!("Dropping ThreadPool to initiate graceful shutdown and join all workers...");
    drop(pool);

    println!(
        "\nAll workers shut down cleanly! Total tasks completed: {}",
        completed_jobs.load(Ordering::SeqCst)
    );
    println!("\n[thread_pool] Completed successfully!\n");
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::time::Duration;

    #[test]
    fn test_thread_pool_execution() {
        let pool = ThreadPool::new(4);
        let counter = Arc::new(AtomicUsize::new(0));

        for _ in 0..20 {
            let counter = Arc::clone(&counter);
            pool.execute(move || {
                counter.fetch_add(1, Ordering::SeqCst);
                thread::sleep(Duration::from_millis(5));
            });
        }

        // Drop pool to wait for all jobs to complete
        drop(pool);

        assert_eq!(counter.load(Ordering::SeqCst), 20);
    }
}
