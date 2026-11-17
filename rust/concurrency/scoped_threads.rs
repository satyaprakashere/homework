//! Example: Scoped Threads (std::thread::scope)
//!
//! Modern Rust fearless concurrency feature (stabilized in Rust 1.63).
//!
//! Why Scoped Threads?
//! With `thread::spawn`, threads require `'static` lifetimes, forcing us to use `Arc`
//! even when threads finish before the function returns.
//! With `std::thread::scope`:
//! - The compiler guarantees all spawned threads finish before `scope` exits.
//! - Threads can safely borrow stack data (references `&T`) without `Arc`!
//! - Borrow checker still statically prevents data races!

use std::thread;

pub fn run() {
    println!("=== 1. Borrowing Stack Data Concurrently (No Arc!) ===");
    let numbers = vec![1, 2, 3, 4, 5, 6, 7, 8];

    thread::scope(|s| {
        // Spawn thread 1 borrowing `numbers`
        s.spawn(|| {
            let sum: i32 = numbers.iter().filter(|&&x| x % 2 == 0).sum();
            println!("   [Worker 1] Sum of even numbers: {}", sum);
        });

        // Spawn thread 2 simultaneously borrowing `numbers`
        s.spawn(|| {
            let sum: i32 = numbers.iter().filter(|&&x| x % 2 != 0).sum();
            println!("   [Worker 2] Sum of odd numbers: {}", sum);
        });

        // The scope automatically joins both threads here!
    });
    // `numbers` is still valid and untouched on the stack:
    println!("Main thread still owns numbers: {:?}", numbers);

    println!("\n=== 2. Parallel Mutation with Disjoint Mutable Slices ===");
    // The borrow checker allows multiple `&mut` as long as they point to disjoint memory regions!
    let mut data = vec![10, 20, 30, 40, 50, 60, 70, 80];
    println!("Before parallel mutation: {:?}", data);

    let mid = data.len() / 2;
    let (left, right) = data.split_at_mut(mid);

    thread::scope(|s| {
        s.spawn(|| {
            println!("   [Worker Left] Doubling elements in first half...");
            for item in left {
                *item *= 2;
            }
        });

        s.spawn(|| {
            println!("   [Worker Right] Tripling elements in second half...");
            for item in right {
                *item *= 3;
            }
        });
    });

    println!("After parallel mutation:  {:?}", data);

    println!("\n=== 3. Returning Values from Scoped Threads ===");
    let text = "fearless concurrency in modern rust";
    let (vowels, consonants) = thread::scope(|s| {
        let h1 = s.spawn(|| {
            text.chars()
                .filter(|c| matches!(c, 'a' | 'e' | 'i' | 'o' | 'u'))
                .count()
        });

        let h2 = s.spawn(|| {
            text.chars()
                .filter(|c| c.is_alphabetic() && !matches!(c, 'a' | 'e' | 'i' | 'o' | 'u'))
                .count()
        });

        (h1.join().unwrap(), h2.join().unwrap())
    });

    println!("Analyzed \"{}\":", text);
    println!("   Vowels: {}", vowels);
    println!("   Consonants: {}", consonants);

    println!("\n[scoped_threads] Completed successfully!\n");
}
