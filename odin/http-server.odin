package main

import "core:fmt"
import "core:net"
import "core:thread"

Connection_Data :: struct {
    client: net.TCP_Socket
}

main :: proc() {
    endpoint := net.Endpoint {
        address = net.IP4_Address{127, 0, 0, 1},
        port    = 8080,
    }

    listener, err := net.listen_tcp(endpoint); if err != nil {
        fmt.eprintf("Failed to bind: %v\n", err)
        return
    }
    defer net.close(listener)

    fmt.println("HTTP server listening on http://127.0.0.1:8080")
    for {
        client, _, accept_err := net.accept_tcp(listener); if accept_err != nil {
            continue
        }

        // Allocate user data for the thread on the heap or pass it safely
        data := new(Connection_Data)
        data.client = client

        // Spawn an explicit OS thread
        t := thread.create_and_start_with_data(data, handle_client)
        // Note: You'd typically want a thread pool or detach/join management
        // depending on your lifetime requirements.
    }
}

handle_client :: proc(t_data: rawptr) {
    data := (^Connection_Data)(t_data)
    defer free(data)
    defer net.close(data.client)

    buf: [1024]u8
    bytes_read, err := net.recv_tcp(data.client, buf[:])
    if err != nil || bytes_read <= 0 {
        return
    }

    body := "Hello from Odin!"
    response := fmt.tprintf(
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: %d\r\n\r\n%s",
        len(body),
        body,
    )

    net.send_tcp(data.client, transmute([]u8)response)
}