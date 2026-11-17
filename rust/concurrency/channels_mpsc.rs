//! Example: Message Passing with Channels (std::sync::mpsc)
//!
//! Demonstrates:
//! 1. `mpsc::channel()` (Multiple Producer, Single Consumer)
//! 2. Ownership transfer over channels preventing data races at compile time
//! 3. Iterating over the receiver (`for msg in rx`)
//! 4. Multiple producers via `tx.clone()`
//! 5. Clean termination when all senders are dropped

use std::sync::mpsc;
use std::thread;
use std::time::Duration;

#[derive(Debug)]
struct Transaction {
    id: u32,
    account: String,
    amount: f64,
}

pub fn run() {
    println!("=== 1. Ownership Transfer Over Channels ===");
    let (tx, rx) = mpsc::channel();

    thread::spawn(move || {
        let payload = String::from("Secret message from background thread");
        println!("   [Sender] Sending payload: \"{}\"", payload);
        tx.send(payload).unwrap();

        // COMPILE ERROR if we uncomment this:
        // println!("Payload is: {}", payload);
        // Rust forbids accessing `payload` after `send` because ownership was moved!
        // This eliminates data races by design.
    });

    let received = rx.recv().expect("Channel sender was dropped");
    println!("[Receiver] Received: \"{}\"", received);

    println!("\n=== 2. Multiple Producers (Cloning the Sender) ===");
    let (tx_orders, rx_orders) = mpsc::channel();

    // Producer 1
    let tx1 = tx_orders.clone();
    thread::spawn(move || {
        let orders = vec![
            Transaction { id: 101, account: "Alice".into(), amount: 150.0 },
            Transaction { id: 102, account: "Alice".into(), amount: 75.5 },
        ];
        for order in orders {
            println!("   [Producer 1 - Alice] sending txn #{}", order.id);
            tx1.send(order).unwrap();
            thread::sleep(Duration::from_millis(30));
        }
    });

    // Producer 2
    let tx2 = tx_orders.clone();
    thread::spawn(move || {
        let orders = vec![
            Transaction { id: 201, account: "Bob".into(), amount: 320.0 },
            Transaction { id: 202, account: "Bob".into(), amount: 45.0 },
        ];
        for order in orders {
            println!("   [Producer 2 - Bob]   sending txn #{}", order.id);
            tx2.send(order).unwrap();
            thread::sleep(Duration::from_millis(40));
        }
    });

    // CRITICAL: We must drop the original `tx_orders` in the main thread!
    // If we keep `tx_orders` alive, the receiver will block forever waiting for more
    // messages because at least one sender is still open.
    drop(tx_orders);

    println!("\n[Consumer] Processing transactions as they arrive:");
    let mut total_volume = 0.0;
    // `rx_orders` implements IntoIterator; the loop ends when all senders drop.
    for txn in rx_orders {
        println!("   Processed: txn #{} for {} (${:.2})", txn.id, txn.account, txn.amount);
        total_volume += txn.amount;
    }

    println!("Total transaction volume processed: ${:.2}", total_volume);
    println!("\n[channels_mpsc] Completed successfully!\n");
}
