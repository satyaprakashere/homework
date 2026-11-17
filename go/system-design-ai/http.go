//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): HTTP PROTOCOL EVOLUTION (1.1 vs 2 vs 3/QUIC)
================================================================================
Key Topics Covered:
1. HTTP/1.1:
   - Persistent TCP Keep-Alive connections.
   - Application Head-Of-Line (HoL) Blocking: Request 2 cannot be processed until Request 1 finishes.
   - Browser workaround: Open 6 concurrent TCP connections per origin.
2. HTTP/2:
   - Binary Framing Layer: Multiplexes multiple bidirectional logical streams over ONE TCP connection.
   - HPACK Header Compression.
   - Fatal Flaw: Transport-Layer HoL Blocking! If a single packet drops, TCP retransmission
     freezes the entire connection, blocking ALL concurrent streams!
3. HTTP/3 (QUIC over UDP):
   - Transport is UDP: Independent streams at the transport layer.
   - Packet drop on Stream A has ZERO effect on Stream B.
   - 0-RTT TLS 1.3 Handshake.
   - Connection Migration (survives WiFi -> Cellular handover via Connection IDs).
================================================================================
*/

type HTTP11Connection struct {
	mu sync.Mutex
}

// Send simulates HTTP/1.1 sequential execution over a single TCP connection
func (c *HTTP11Connection) Send(requests []string) time.Duration {
	c.mu.Lock()
	defer c.mu.Unlock()

	start := time.Now()
	for _, req := range requests {
		// HoL blocking: each request must wait for preceding request to complete
		time.Sleep(15 * time.Millisecond)
		_ = req
	}
	return time.Since(start)
}

type HTTP2StreamMultiplexer struct{}

// SendMultiplexed simulates HTTP/2 multiplexing multiple streams over 1 connection
func (m *HTTP2StreamMultiplexer) SendMultiplexed(requests []string, packetLoss bool) time.Duration {
	start := time.Now()

	if packetLoss {
		// TCP Head-of-Line blocking: all streams stall due to TCP retransmission!
		time.Sleep(45 * time.Millisecond) // TCP stall penalty
		return time.Since(start)
	}

	var wg sync.WaitGroup
	for _, req := range requests {
		wg.Add(1)
		go func(r string) {
			defer wg.Done()
			time.Sleep(15 * time.Millisecond)
		}(req)
	}
	wg.Wait()
	return time.Since(start)
}

type HTTP3QUICMultiplexer struct{}

// SendQUIC simulates HTTP/3 where packet loss on one stream does NOT block other streams
func (q *HTTP3QUICMultiplexer) SendQUIC(requests []string, packetLossOnOneStream bool) time.Duration {
	start := time.Now()
	var wg sync.WaitGroup

	for i, req := range requests {
		wg.Add(1)
		go func(streamID int, r string) {
			defer wg.Done()
			if packetLossOnOneStream && streamID == 0 {
				// Only Stream 0 suffers retransmission penalty!
				time.Sleep(40 * time.Millisecond)
			} else {
				// Other streams complete with zero HoL delay!
				time.Sleep(15 * time.Millisecond)
			}
		}(i, req)
	}
	wg.Wait()
	return time.Since(start)
}

func main() {
	fmt.Println("=== SD3 HTTP Evolution: HTTP/1.1 vs HTTP/2 vs HTTP/3 (QUIC) ===")

	requests := []string{"GET /style.css", "GET /app.js", "GET /hero.png", "GET /api/user"}

	// 1. HTTP/1.1 (Sequential Head-of-Line Blocking)
	h1 := &HTTP11Connection{}
	d1 := h1.Send(requests)
	fmt.Printf("\n[1] HTTP/1.1 (1 TCP connection, sequential HoL blocking):\n")
	fmt.Printf("    Processed 4 requests in: %v\n", d1)

	// 2. HTTP/2 (Multiplexed over single TCP - Happy Path)
	h2 := &HTTP2StreamMultiplexer{}
	d2 := h2.SendMultiplexed(requests, false)
	fmt.Printf("\n[2] HTTP/2 (Multiplexed streams, no packet loss):\n")
	fmt.Printf("    Processed 4 streams concurrently in: %v (~3x speedup!)\n", d2)

	// 3. HTTP/2 under 2% Packet Loss (TCP-level HoL stall)
	d2Loss := h2.SendMultiplexed(requests, true)
	fmt.Printf("\n[3] HTTP/2 with TCP Packet Loss:\n")
	fmt.Printf("    Single packet dropped -> ALL streams stalled: %v\n", d2Loss)

	// 4. HTTP/3 (QUIC over UDP with independent streams)
	h3 := &HTTP3QUICMultiplexer{}
	d3 := h3.SendQUIC(requests, true)
	fmt.Printf("\n[4] HTTP/3 QUIC (UDP independent streams, packet loss on Stream 0):\n")
	fmt.Printf("    Streams 1, 2, 3 finished in 15ms; only dropped stream retransmitted: %v\n", d3)

	fmt.Println("\n[SD3 Takeaway]: HTTP/2 solves application HoL blocking via binary frames; HTTP/3 solves TCP transport HoL blocking via UDP streams.")
}
