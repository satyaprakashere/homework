//! Example: Bounded Synchronous Channels (std::sync::mpsc::sync_channel)
//!
//! Demonstrates:
//! 1. `mpsc::sync_channel(bound)` for backpressure
//! 2. Zero-capacity rendezvous channels (rendezvous synchronization)
//! 3. Non-blocking operations: `try_send` and `try_recv`
//! 4. Handling buffer full / empty states without blocking

use std::sync::mpsc::{self, TryRecvError, TrySendError};
use std::thread;
use std::time::Duration;

pub fn run() {
    println!("=== 1. Bounded Channel with Backpressure (Capacity = 2) ===");
    let (tx, rx) = mpsc::sync_channel(2);

    let producer = thread::spawn(move || {
        for i in 1..=5 {
            println!("   [Producer] Attempting to send item {}", i);
            tx.send(i).unwrap();
            println!("   [Producer] -> Item {} sent successfully", i);
        }
        println!("   [Producer] All items sent.");
    });

    thread::sleep(Duration::from_millis(50));
    println!("[Consumer] Starting slow consumer to demonstrate backpressure...");
    for _ in 1..=5 {
        thread::sleep(Duration::from_millis(60));
        let item = rx.recv().unwrap();
        println!("[Consumer] <- Received item {}", item);
    }

    producer.join().unwrap();

    println!("\n=== 2. Zero-Capacity Rendezvous Channel ===");
    // Capacity 0 means a send will block until another thread calls recv()!
    // This creates an instantaneous rendezvous handoff between threads.
    let (rendezvous_tx, rendezvous_rx) = mpsc::sync_channel(0);

    let sender_thread = thread::spawn(move || {
        println!("   [Rendezvous Sender] Waiting for receiver to meet...");
        rendezvous_tx.send("Handshake token").unwrap();
        println!("   [Rendezvous Sender] Receiver has received the token! Resuming.");
    });

    thread::sleep(Duration::from_millis(80));
    println!("[Rendezvous Receiver] Arrived at rendezvous point!");
    let token = rendezvous_rx.recv().unwrap();
    println!("[Rendezvous Receiver] Got token: \"{}\"", token);

    sender_thread.join().unwrap();

    println!("\n=== 3. Non-blocking try_send and try_recv ===");
    let (tx_nb, rx_nb) = mpsc::sync_channel(1);

    // First send succeeds because capacity is 1
    match tx_nb.try_send(42) {
        Ok(()) => println!("   Successfully sent 42 without blocking"),
        Err(e) => println!("   Failed: {:?}", e),
    }

    // Second send immediately fails because buffer is full
    match tx_nb.try_send(99) {
        Ok(()) => println!("   Sent 99"),
        Err(TrySendError::Full(val)) => {
            println!("   Buffer is full! Could not send {}, avoided blocking!", val);
        }
        Err(TrySendError::Disconnected(_)) => println!("   Channel disconnected"),
    }

    // Consume the item
    assert_eq!(rx_nb.try_recv(), Ok(42));

    // Try receive when empty
    match rx_nb.try_recv() {
        Ok(v) => println!("   Got: {}", v),
        Err(TryRecvError::Empty) => println!("   Channel is empty, non-blocking check confirmed!"),
        Err(TryRecvError::Disconnected) => println!("   Channel disconnected"),
    }

    println!("\n[bounded_channels] Completed successfully!\n");
}
