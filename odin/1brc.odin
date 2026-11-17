package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:mem/virtual"
import "core:thread"

// ----------------------------------------------------------------------------
// Data Structures & Constants
// ----------------------------------------------------------------------------

TABLE_SIZE :: 1024 // 1BRC contains max ~400 unique station names
MAX_NAME_LEN :: 100

// Fixed-point stat tracking to avoid double/float rounding overhead
Station_Stats :: struct {
    name:     [MAX_NAME_LEN]u8,
    name_len: int,
    min:      i32,
    max:      i32,
    sum:      i64,
    count:    i64,
}

// Custom linear-probing hash table for ultra-fast lookup per thread
Hash_Table :: struct {
    entries: [TABLE_SIZE]Station_Stats,
    used:    [TABLE_SIZE]bool,
}

Worker_Context :: struct {
    data:  []u8,
    table: Hash_Table,
}

// ----------------------------------------------------------------------------
// Core Parsing Optimizations
// ----------------------------------------------------------------------------

// Fast 64-bit FNV-1a style hash over bytes
hash_bytes :: #force_inline proc(b: []u8) -> u64 {
    h: u64 = 0xcbf29ce484222325
    for byte in b {
        h ~= u64(byte)
        h *= 0x100000001b3
    }
    return h
}

// Branchless fixed-point number parser (e.g., "-12.3" -> -123)

parse_temp :: #force_inline proc(data: []u8, idx: ^int) -> i32 {
    neg := i32(1)
    if data[idx^] == '-' {
        neg = -1
        idx^ += 1
    }

    val := i32(0)
    for data[idx^] != '\n' && data[idx^] != '\r' {
        if data[idx^] != '.' {
            val = val * 10 + i32(data[idx^] - '0')
        }
        idx^ += 1
    }

    // Skip newline byte(s)
    if data[idx^] == '\r' do idx^ += 1
    if data[idx^] == '\n' do idx^ += 1

    return val * neg
}

// ----------------------------------------------------------------------------
// Worker Thread Loop
// ----------------------------------------------------------------------------

worker_proc :: proc(t: ^thread.Thread) {
    ctx := cast(^Worker_Context)t.data
    data := ctx.data
    table := &ctx.table

    i := 0
    n := len(data)

    for i < n {
        name_start := i

        // Scan for semicolon ';'
        for i < n && data[i] != ';' {
            i += 1
        }

        if i >= n do break

        name_bytes := data[name_start:i]
        i += 1 // Skip ';'

        temp := parse_temp(data, &i)

        // Linear probing hash table lookup
        hash := hash_bytes(name_bytes)
        slot := int(hash % TABLE_SIZE)

        for {
            if !table.used[slot] {
                // Insert new station
                table.used[slot] = true
                copy(table.entries[slot].name[:], name_bytes)
                table.entries[slot].name_len = len(name_bytes)
                table.entries[slot].min = temp
                table.entries[slot].max = temp
                table.entries[slot].sum = i64(temp)
                table.entries[slot].count = 1
                break
            }

            entry := &table.entries[slot]
            if entry.name_len == len(name_bytes) &&
               slice.equal(entry.name[:entry.name_len], name_bytes) {
                // Update existing station statistics
                if temp < entry.min do entry.min = temp
                if temp > entry.max do entry.max = temp
                entry.sum += i64(temp)
                entry.count += 1
                break
            }

            slot = (slot + 1) % TABLE_SIZE
        }
    }
}

// ----------------------------------------------------------------------------
// Main Program Setup & Aggregation
// ----------------------------------------------------------------------------

main :: proc() {
    file_path := "measurements.txt"
    if len(os.args) > 1 {
        file_path = os.args[1]
    }

    // 1. Zero-copy Memory-Map the entire file into process virtual memory
    data, err := virtual.map_file(file_path, {.Read})
    if err != nil {
        fmt.eprintln("Failed to mmap file:", err)
        return
    }
    defer virtual.release(raw_data(data), len(data))

    num_threads := 16 // Match physical logical cores
    threads := make([]^thread.Thread, num_threads)
    contexts := make([]Worker_Context, num_threads)

    chunk_size := len(data) / num_threads

    // 2. Partition file into chunks aligned at newline boundaries
    start := 0
    for t in 0 ..< num_threads {
        end := start + chunk_size
        if t == num_threads - 1 {
            end = len(data)
        } else {
            // Advance end pointer to the next line break
            for end < len(data) && data[end] != '\n' {
                end += 1
            }
            if end < len(data) do end += 1 // Include '\n'
        }

        contexts[t].data = data[start:end]
        threads[t] = thread.create(worker_proc)
        threads[t].data = &contexts[t]
        thread.start(threads[t])

        start = end
    }

    // 3. Join all worker threads
    for t in 0 ..< num_threads {
        thread.destroy(threads[t])
    }

    // 4. Merge hash tables across worker threads
    global_table: Hash_Table
    for t in 0 ..< num_threads {
        worker_table := &contexts[t].table
        for idx in 0 ..< TABLE_SIZE {
            if !worker_table.used[idx] do continue

            w_entry := &worker_table.entries[idx]
            w_name := w_entry.name[:w_entry.name_len]

            hash := hash_bytes(w_name)
            slot := int(hash % TABLE_SIZE)

            for {
                if !global_table.used[slot] {
                    global_table.used[slot] = true
                    global_table.entries[slot] = w_entry^
                    break
                }

                g_entry := &global_table.entries[slot]
                if g_entry.name_len == len(w_name) &&
                   slice.equal(g_entry.name[:g_entry.name_len], w_name) {
                    if w_entry.min < g_entry.min do g_entry.min = w_entry.min
                    if w_entry.max > g_entry.max do g_entry.max = w_entry.max
                    g_entry.sum += w_entry.sum
                    g_entry.count += w_entry.count
                    break
                }

                slot = (slot + 1) % TABLE_SIZE
            }
        }
    }

    // 5. Collect, Sort, and Print Output
    Result :: struct {
        name: string,
        min:  f64,
        mean: f64,
        max:  f64,
    }

    results := make([dynamic]Result, 0, 500)

    for idx in 0 ..< TABLE_SIZE {
        if !global_table.used[idx] do continue
        entry := &global_table.entries[idx]

        append(&results, Result{
            name = string(entry.name[:entry.name_len]),
            min  = f64(entry.min) / 10.0,
            mean = (f64(entry.sum) / f64(entry.count)) / 10.0,
            max  = f64(entry.max) / 10.0,
        })
    }

    // Sort output alphabetically by station name
    slice.sort_by(results[:], proc(a, b: Result) -> bool {
        return a.name < b.name
    })

    // Print formatted result to match 1BRC spec
    fmt.print("{")
    for r, i in results {
        fmt.printf("%s=%.1f/%.1f/%.1f", r.name, r.min, r.mean, r.max)
        if i < len(results) - 1 {
            fmt.print(", ")
        }
    }
    fmt.println("}")
}
