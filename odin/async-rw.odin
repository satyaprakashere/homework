package main

import "core:fmt"
import "core:nbio"

main :: proc() {
    // 1. Acquire the thread event loop
    if err := nbio.acquire_thread_event_loop(); err != nil {
        fmt.eprintln("Failed to acquire event loop:", nbio.error_string(err))
        return
    }
    defer nbio.release_thread_event_loop()

    // 2. Queue the asynchronous file open operation
    // This returns an operation pointer and triggers `on_file_opened` when ready
    nbio.open("cheatsheet.md", on_file_opened)
    nbio.open("collection.odin", on_file_opened)
    
    fmt.println("Async open queued. Running event loop...")

    // 3. Run the event loop ticks until all tasks finish
    err := nbio.run()
    assert(err == nil)
}

// 4. Handle the opened file handle and initiate the async read
on_file_opened :: proc(op: ^nbio.Operation) {
    if op.open.err != nil {
        fmt.eprintfln("File open error: %v", nbio.error_string(op.open.err))
        return
    }

    // Extract the valid file handle from the completed open operation
    file := op.open.handle
    
    // Allocate a buffer to hold the read data
    buf := make([]byte, 1024)
    
    // Queue the asynchronous read operation, passing context/cleanup if needed
    // Note: nbio file reads take a positional offset (0 here)
    nbio.read(file, 0, buf, on_file_read)
}

// 5. Callback invoked asynchronously when the read completes
on_file_read :: proc(op: ^nbio.Operation) {
    if op.read.err != nil {
        fmt.eprintfln("File read error: %v", nbio.error_string(op.read.err))
        // Remember to close the file handle if an error cuts things short
        nbio.close(op.open.handle)
        return
    }

    // Clean up the file handle when done
    defer nbio.close(op.open.handle)

    // Extract and print the bytes read successfully
    data_read := op.read.buf[0:op.read.read]
    fmt.printfln("Successfully read %d bytes asynchronously:", op.read.read)
    fmt.println(string(data_read))
    
    // Free the buffer we allocated earlier
    delete(op.read.buf)
}