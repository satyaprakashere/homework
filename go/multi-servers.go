//go:build ignore
package main

import (
    "fmt"
    "log"
    "net/http"
    "strconv"
)

func startServer(port int) {
    handler := func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from port %d\n", port)
    }

    mux := http.NewServeMux()
    mux.HandleFunc("/", handler)

    addr := ":" + strconv.Itoa(port)
    go func() {
        log.Printf("Starting server on port %d", port)
        err := http.ListenAndServe(addr, mux)
        if err != nil {
            log.Printf("Failed on port %d: %v", port, err)
        }
    }()
}

func main() {
    startPort := 8000
    endPort := 8999 // 10000 servers

    for port := startPort; port <= endPort; port++ {
        startServer(port)
    }

    // Keep the main goroutine alive
    select {}
}
