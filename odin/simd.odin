package main

import "core:fmt"
import "core:time"
import "core:mem"
import "core:mem/virtual"
import "core:slice"

// Define a 256-bit SIMD vector containing 8x f32 floats (AVX equivalent)
Vec8f :: #simd[8]f32

N :: 100_000_00

// 32-byte aligned allocations for SIMD compatibility (256-bit = 32 bytes)
ALIGNMENT :: 32

main :: proc() {
//  arena: mem.Arena
//  mem.arena_init(&arena, make([]byte, 1024 * 1024 * 1024)) // 1GB buffer
////  defer mem.arena_free_all(&arena)
//
//  context.allocator = mem.arena_allocator(&arena)

    // 1. Reserve virtual address space (e.g., 1 Gigabyte)
    arena: virtual.Arena
    err := virtual.arena_init_static(&arena, 1024 * mem.Gigabyte)
    if err != .None {
        fmt.println("Failed to init virtual arena:", err)
        return
    }
    allocator := virtual.arena_allocator(&arena)

    //  defer virtual.arena_destroy(&arena)
    
    // 2. Get the allocator interface
    context.allocator = allocator
        
    a_raw, _ := mem.alloc_bytes(size_of(f32) * N, ALIGNMENT)
    b_raw, _ := mem.alloc_bytes(size_of(f32) * N, ALIGNMENT)
    c_raw, _ := mem.alloc_bytes(size_of(f32) * N, ALIGNMENT)

    // 1. Allocate arrays on heap
    a := slice.from_ptr((^f32)(raw_data(a_raw)), N)
    b := slice.from_ptr((^f32)(raw_data(b_raw)), N)
    c := slice.from_ptr((^f32)(raw_data(c_raw)), N)

    // Populate initial data
    for i in 0..<N {
        a[i] = f32(i)
        b[i] = 2.0
    }

    // -------------------------------------------------------------
    // Benchmark 1: Standard Scalar Loop
    // -------------------------------------------------------------
    start_scalar := time.now()

    for i in 0..<N {
        c[i] = a[i] * b[i]
    }

    duration_scalar := time.since(start_scalar)
    fmt.printf("Scalar Loop Execution Time : %v\n", duration_scalar)

    // -------------------------------------------------------------
    // Benchmark 2: Explicit SIMD Loop (8 elements per step)
    // -------------------------------------------------------------
    start_simd := time.now()

    for i := 0; i < N; i += 8 {
        // Cast pointers to vector register references
        va := (^Vec8f)(&a[i])^
        vb := (^Vec8f)(&b[i])^

        // Executes single vector instruction on CPU
        vc := va * vb

        // Store result back to memory
        (^Vec8f)(&c[i])^ = vc
    }

    duration_simd := time.since(start_simd)
    fmt.printf("SIMD Loop Execution Time   : %v\n", duration_simd)

    // -------------------------------------------------------------
    // Calculate Speedup & Format Milliseconds explicitly
    // -------------------------------------------------------------
    ms_scalar := time.duration_milliseconds(duration_scalar)
    ms_simd   := time.duration_milliseconds(duration_simd)
    
    fmt.printf("\n--- Results Summary ---\n")
    fmt.printf("Scalar Time : %.3f ms\n", ms_scalar)
    fmt.printf("SIMD Time   : %.3f ms\n", ms_simd)
    fmt.printf("Speedup     : %.2fx faster\n", ms_scalar / ms_simd)
}