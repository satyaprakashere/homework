//! Example: Parallel Multi-Stage Pipeline
//!
//! Demonstrates:
//! 1. Multi-stage streaming pipeline using channels
//! 2. Stage 1 (Generator) -> Stage 2 (Transformer) -> Stage 3 (Aggregator)
//! 3. Parallel pipelined throughput with lock-free handoffs
//! 4. Clean EOF propagation across stages

use std::sync::mpsc;
use std::thread;
use std::time::Duration;

#[derive(Debug)]
struct RawRecord {
    id: usize,
    sensor: &'static str,
    value: f64,
}

#[derive(Debug)]
struct ProcessedRecord {
    id: usize,
    sensor: &'static str,
    normalized_value: f64,
    anomaly: bool,
}

pub fn run() {
    println!("=== Multi-Stage Producer-Consumer Data Pipeline ===\n");

    // Stage 1 -> Stage 2 channel
    let (gen_tx, gen_rx) = mpsc::sync_channel(4);
    // Stage 2 -> Stage 3 channel
    let (proc_tx, proc_rx) = mpsc::sync_channel(4);

    // Stage 1: Generator
    let stage1 = thread::spawn(move || {
        let raw_data = vec![
            RawRecord { id: 1, sensor: "temp_north", value: 23.5 },
            RawRecord { id: 2, sensor: "temp_south", value: 48.2 }, // anomaly
            RawRecord { id: 3, sensor: "temp_north", value: 24.1 },
            RawRecord { id: 4, sensor: "temp_east",  value: -5.0 }, // anomaly
            RawRecord { id: 5, sensor: "temp_south", value: 25.0 },
            RawRecord { id: 6, sensor: "temp_east",  value: 22.8 },
        ];

        for record in raw_data {
            println!("   [Stage 1: Generator] Emitting record #{}", record.id);
            gen_tx.send(record).unwrap();
            thread::sleep(Duration::from_millis(25));
        }
        println!("   [Stage 1: Generator] Completed data stream.");
    });

    // Stage 2: Transformer / Anomaly Detector
    let stage2 = thread::spawn(move || {
        for raw in gen_rx {
            // Check for anomalies and normalize
            let anomaly = raw.value < 0.0 || raw.value > 45.0;
            let normalized = (raw.value - 20.0) / 10.0;
            let processed = ProcessedRecord {
                id: raw.id,
                sensor: raw.sensor,
                normalized_value: normalized,
                anomaly,
            };

            println!(
                "   [Stage 2: Transformer] Processed #{:02}: norm={:.2}, anomaly={}",
                processed.id, processed.normalized_value, processed.anomaly
            );

            proc_tx.send(processed).unwrap();
            thread::sleep(Duration::from_millis(30));
        }
        println!("   [Stage 2: Transformer] Input closed. Flushed all records.");
    });

    // Stage 3: Aggregator / Reporter (runs in main thread)
    let mut total_records = 0;
    let mut anomaly_count = 0;

    println!("[Stage 3: Aggregator] Listening for processed records...\n");
    for item in proc_rx {
        total_records += 1;
        if item.anomaly {
            anomaly_count += 1;
            println!("   >>> [ALERT] Detected anomaly on sensor '{}' in record #{:?}", item.sensor, item);
        }
    }

    stage1.join().unwrap();
    stage2.join().unwrap();

    println!("\nPipeline Processing Summary:");
    println!("   Total records processed: {}", total_records);
    println!("   Anomalies identified:    {}", anomaly_count);
    println!("\n[parallel_pipeline] Completed successfully!\n");
}
