package main

import "core:fmt"
import "core:time"

main :: proc() {
    // Define timeframes for different hierarchical levels
    PHYSICS_TICK_RATE  :: 120.0                                // Higher frequency (smaller timeframe)
    PHYSICS_STEP       :: time.Second / time.Duration(PHYSICS_TICK_RATE) // ~8.33ms

    RENDER_TARGET_FPS  :: 60.0
    RENDER_FRAME_TIME  :: time.Second / time.Duration(RENDER_TARGET_FPS) // ~16.66ms

    NETWORK_TICK_RATE  :: 20.0                                 // Lower frequency (larger timeframe)
    NETWORK_STEP       :: time.Second / time.Duration(NETWORK_TICK_RATE) // 50.0ms

    running := true
    
    // Accumulators to track elapsed time for each subsystem
    physics_accumulator: time.Duration
    network_accumulator: time.Duration

    frame_start := time.now()
    last_time := frame_start

    for running {
        current_time := time.now()
        frame_delta := time.since(last_time)
        last_time = current_time

        // Add elapsed time to our sub-system accumulators
        physics_accumulator += frame_delta
        network_accumulator += frame_delta

        // ---------------------------------------------------------
        // LEVEL 1: Smallest Timeframe (Physics / Sub-steps)
        // Runs as many times as needed to catch up with real time
        // ---------------------------------------------------------
        for physics_accumulator >= PHYSICS_STEP {
            update_physics(f32(time.duration_seconds(PHYSICS_STEP)))
            physics_accumulator -= PHYSICS_STEP
        }

        // ---------------------------------------------------------
        // LEVEL 2: Medium Timeframe (Network / Logic Ticks)
        // ---------------------------------------------------------
        for network_accumulator >= NETWORK_STEP {
            update_network()
            network_accumulator -= NETWORK_STEP
        }

        // ---------------------------------------------------------
        // LEVEL 3: Base Timeframe (Rendering / Display)
        // Runs once per frame, interpolating physics states if necessary
        // ---------------------------------------------------------
        render_frame()

        // Frame rate limiter for the outer render loop
        elapsed := time.since(current_time)
        if elapsed < RENDER_FRAME_TIME {
            time.sleep(RENDER_FRAME_TIME - elapsed)
        }
    }
}

// Dummy subsystem stubs
update_physics :: proc(dt: f32) {
    // High-frequency deterministic updates
}

update_network :: proc() {
    // Low-frequency sync updates
}

render_frame :: proc() {
    // Draw to screen
}