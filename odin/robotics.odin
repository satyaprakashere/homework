/* STREAMING_CHUNK:Defining package and importing required core libraries... */
package main

import "core:fmt"
import "core:sync/barrier"
import "core:thread"
import "core:time"

// ============================================================================
// INVERTED TIMESCALE HIERARCHY SIMULATOR (ODIN LANG)
//
// Structure (Inverted Hierarchy Tree - Frequency decreases / Timescale increases down):
//
// [ LEVEL 0: IO EVENTS ] -> [ LEVEL 0: IO EVENTS ]   (~1,000 Hz / 1ms step - Top Leaves)
//           \                    /
//            \                  /
//             [  LEVEL 1: MIND  ]                   (~100 Hz / 10ms step)
//                     |
//             [ LEVEL 2: INTELLECT ]                (~10 Hz / 100ms step)
//                     |
//             [  LEVEL 3: MEMORY   ]                (~1 Hz / 1s step)
//                     |
//             [ LEVEL 4: CONSCIOUSNESS ]            (~0.1 Hz / 10s step - Base Root)
// ============================================================================

/* STREAMING_CHUNK:Defining timescale enum layers... */
Timescale_Level :: enum {
	IO_Events,     // Top Leaves: High-frequency input/sensor sampling (1ms)
	Mind,          // Fast reactive processing & dynamic attention (10ms)
	Intellect,     // Analytical evaluation, decision trees & planning (100ms)
	Memory,        // Long-term consolidation, pattern matching & caching (1s)
	Consciousness, // Base Root: Slow integration, state maintenance & clock synthesis (10s)
}

/* STREAMING_CHUNK:Defining node configuration and cognitive state structures... */
// Hierarchy Node configuration
Node_Config :: struct {
	level:       Timescale_Level,
	name:        string,
	tick_period: time.Duration,
	tick_count:  u64,
	last_tick:   time.Time,
}

// Shared hierarchical state passed down through integration
Cognitive_State :: struct {
	sensor_io_buffer:   f64,
	mind_focus_vector:  f64,
	intellect_decision: f64,
	memory_record_id:   u64,
	consciousness_bias: f64,
}

// Engine controller context
Hierarchy_Engine :: struct {
	is_running:      bool,
	state:           Cognitive_State,
	nodes:           [Timescale_Level]Node_Config,
	start_timestamp: time.Time,
}

/* STREAMING_CHUNK:Initializing the hierarchy engine configuration... */
// ----------------------------------------------------------------------------
// NODE INITIALIZATION
// ----------------------------------------------------------------------------
init_engine :: proc(engine: ^Hierarchy_Engine) {
	engine.is_running = true
	engine.start_timestamp = time.now()
	engine.state = Cognitive_State{
		sensor_io_buffer   = 0.0,
		mind_focus_vector  = 0.0,
		intellect_decision = 0.0,
		memory_record_id   = 0,
		consciousness_bias = 1.0,
	}

	// Define timescales (Higher up = smaller timeframe / Lower down = larger timeframe)
	engine.nodes[.IO_Events] = Node_Config{
		level       = .IO_Events,
		name        = "IO Events (Leaves)",
		tick_period = 1 * time.Millisecond,
	}
	engine.nodes[.Mind] = Node_Config{
		level       = .Mind,
		name        = "Mind (Reactive Layer)",
		tick_period = 10 * time.Millisecond,
	}
	engine.nodes[.Intellect] = Node_Config{
		level       = .Intellect,
		name        = "Intellect (Analysis & Planning)",
		tick_period = 100 * time.Millisecond,
	}
	engine.nodes[.Memory] = Node_Config{
		level       = .Memory,
		name        = "Memory (Consolidation)",
		tick_period = 1 * time.Second,
	}
	engine.nodes[.Consciousness] = Node_Config{
		level       = .Consciousness,
		name        = "Consciousness (Base Root)",
		tick_period = 10 * time.Second,
	}
}

/* STREAMING_CHUNK:Defining layer execution tick handlers... */
// ----------------------------------------------------------------------------
// TIMESCALE LAYER EXECUTION HANDLERS
// ----------------------------------------------------------------------------

process_io_events :: proc(engine: ^Hierarchy_Engine, dt: f64) {
	// Top Leaves: Rapid, high-frequency IO polling & noise integration
	engine.state.sensor_io_buffer += (dt * 1000.0)
	engine.nodes[.IO_Events].tick_count += 1
}

process_mind :: proc(engine: ^Hierarchy_Engine, dt: f64) {
	// Level 1: Aggregates rapid IO noise into directed sensory attention
	engine.state.mind_focus_vector = engine.state.sensor_io_buffer * 0.05
	engine.nodes[.Mind].tick_count += 1
}

process_intellect :: proc(engine: ^Hierarchy_Engine, dt: f64) {
	// Level 2: Synthesizes mind vectors to evaluate decisions & logical paths
	engine.state.intellect_decision = engine.state.mind_focus_vector * engine.state.consciousness_bias
	engine.nodes[.Intellect].tick_count += 1
	
	fmt.printfln("[TICK: INTELLECT] Period: 100ms | Decision Value: %.4f", engine.state.intellect_decision)
}

process_memory :: proc(engine: ^Hierarchy_Engine, dt: f64) {
	// Level 3: Stores decision snapshots into persistent state
	engine.state.memory_record_id += 1
	engine.nodes[.Memory].tick_count += 1
	
	fmt.printfln("==========================================================")
	fmt.printfln("[TICK: MEMORY] Period: 1s | Logged Record #%d | Intellect State: %.4f", 
		engine.state.memory_record_id, engine.state.intellect_decision)
	fmt.printfln("==========================================================")
}

process_consciousness :: proc(engine: ^Hierarchy_Engine, dt: f64) {
	// Level 4 (Base Root): Grounding temporal anchor & global modulation rate
	engine.state.consciousness_bias += 0.1
	engine.nodes[.Consciousness].tick_count += 1

	fmt.printfln("**********************************************************")
	fmt.printfln("[ROOT: CONSCIOUSNESS] Period: 10s | Synchronized State Shift! Global Bias: %.2f", 
		engine.state.consciousness_bias)
	fmt.printfln("**********************************************************")
}

/* STREAMING_CHUNK:Implementing top-down multi-rate accumulator loop... */
// ----------------------------------------------------------------------------
// MAIN ACCUMULATOR LOOP (INVERTED HIERARCHY TICK SCHEDULER)
// ----------------------------------------------------------------------------

run_hierarchy_loop :: proc(engine: ^Hierarchy_Engine, max_runtime: time.Duration) {
	// Accumulator buffers for each timescale layer
	accumulators: [Timescale_Level]time.Duration

	start_time := time.now()
	last_time := start_time

	fmt.println(">>> Starting Inverted Timescale Cognitive Tree Engine <<<\n")

	for engine.is_running {
		current_time := time.now()
		elapsed_total := time.since(start_time)

		if elapsed_total >= max_runtime {
			engine.is_running = false
			break
		}

		frame_delta := time.since(last_time)
		last_time = current_time

		// Add frame delta to all level accumulators
		for lvl in Timescale_Level {
			accumulators[lvl] += frame_delta
		}

		dt := f64(time.duration_seconds(frame_delta))

		// --------------------------------------------------------------------
		// TOP-DOWN / HIGH-TO-LOW CASCADE EVALUATION
		// --------------------------------------------------------------------

		// Level 0: IO Events (~1ms)
		for accumulators[.IO_Events] >= engine.nodes[.IO_Events].tick_period {
			process_io_events(engine, dt)
			accumulators[.IO_Events] -= engine.nodes[.IO_Events].tick_period
		}

		// Level 1: Mind (~10ms)
		for accumulators[.Mind] >= engine.nodes[.Mind].tick_period {
			process_mind(engine, dt)
			accumulators[.Mind] -= engine.nodes[.Mind].tick_period
		}

		// Level 2: Intellect (~100ms)
		for accumulators[.Intellect] >= engine.nodes[.Intellect].tick_period {
			process_intellect(engine, dt)
			accumulators[.Intellect] -= engine.nodes[.Intellect].tick_period
		}

		// Level 3: Memory (~1s)
		for accumulators[.Memory] >= engine.nodes[.Memory].tick_period {
			process_memory(engine, dt)
			accumulators[.Memory] -= engine.nodes[.Memory].tick_period
		}

		// Level 4: Consciousness (~10s - Base Root)
		for accumulators[.Consciousness] >= engine.nodes[.Consciousness].tick_period {
			process_consciousness(engine, dt)
			accumulators[.Consciousness] -= engine.nodes[.Consciousness].tick_period
		}

		// Yield briefly to avoid maxing out 100% CPU thread core
		time.sleep(200 * time.Microsecond)
	}
}

/* STREAMING_CHUNK:Defining main entry point and execution summary... */
// ----------------------------------------------------------------------------
// ENTRY POINT
// ----------------------------------------------------------------------------

main :: proc() {
	engine: Hierarchy_Engine
	init_engine(&engine)

	// Run simulation engine for 12 seconds to observe all hierarchical layers tick
	run_hierarchy_loop(&engine, 12 * time.Second)

	fmt.println("\n>>> Simulation Complete. Final Execution Telemetry: <<<")
	for lvl in Timescale_Level {
		node := engine.nodes[lvl]
		fmt.printfln("Layer [%-20s] | Period: %-8v | Total Ticks: %d", 
			node.name, node.tick_period, node.tick_count)
	}
}