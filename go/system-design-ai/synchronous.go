//go:build ignore

package main

import (
	"context"
	"fmt"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): SYNCHRONOUS RPCs, CASCADING FAILURES & HEDGING
================================================================================
Key Topics Covered:
1. The Hazard of Synchronous Blocking Call Chains:
   - Client -> Service A -> Service B -> Service C.
   - If Service C degrades (latency spikes from 10ms to 2000ms), Service B exhausts its thread pool,
     Service A exhausts its thread pool, causing a system-wide catastrophic Cascading Failure.
2. Mitigation 1: Hard Deadline Timeouts:
   - Every synchronous hop MUST respect a strict context.WithTimeout budget.
3. Mitigation 2: Request Hedging (Tied Requests):
   - Google "The Tail at Scale" (Dean & Barroso).
   - If the primary server doesn't respond within the expected p95 latency (e.g. 25ms),
     fire a second identical request to a hedged replica. Use whichever arrives first!
   - Cuts P99 tail latency by up to 80% with minimal extra server load.
================================================================================
*/

type DownstreamServer struct {
	ID        int
	baseDelay time.Duration
	isSlow    atomic.Bool
}

func (s *DownstreamServer) Call(ctx context.Context) (string, error) {
	delay := s.baseDelay
	if s.isSlow.Load() {
		delay = 100 * time.Millisecond // 10x latency spike (tail latency anomaly)
	}

	select {
	case <-time.After(delay):
		return fmt.Sprintf("Response from Server #%d (latency: %v)", s.ID, delay), nil
	case <-ctx.Done():
		return "", ctx.Err()
	}
}

// RequestHedge sends request to primary, and fires a hedged backup if p95 threshold passes
func RequestHedge(ctx context.Context, primary, backup *DownstreamServer, p95Threshold time.Duration) (string, time.Duration) {
	start := time.Now()
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	resultChan := make(chan string, 2)

	// Send to Primary
	go func() {
		res, err := primary.Call(ctx)
		if err == nil {
			resultChan <- res
		}
	}()

	// Wait for p95 threshold before deciding to hedge
	select {
	case res := <-resultChan:
		return res, time.Since(start) // Primary returned fast! No hedge needed.
	case <-time.After(p95Threshold):
		fmt.Printf("  [HEDGE TRIGGERED] Primary Server #%d exceeded p95 threshold (%v). Firing hedged backup!\n",
			primary.ID, p95Threshold)
	case <-ctx.Done():
		return "", time.Since(start)
	}

	// Fire Hedged Backup to secondary server
	go func() {
		res, err := backup.Call(ctx)
		if err == nil {
			resultChan <- res
		}
	}()

	// Return whichever server finishes first
	select {
	case res := <-resultChan:
		return res, time.Since(start)
	case <-ctx.Done():
		return "", time.Since(start)
	}
}

func main() {
	fmt.Println("=== SD3 Synchronous Systems: Cascading Failure Defenses & Request Hedging ===")

	serverA := &DownstreamServer{ID: 1, baseDelay: 10 * time.Millisecond}
	serverB := &DownstreamServer{ID: 2, baseDelay: 10 * time.Millisecond}

	// 1. Normal Fast Synchronous Call
	fmt.Println("\n[1] Normal Call: Primary server healthy (< p95):")
	ctx := context.Background()
	res1, d1 := RequestHedge(ctx, serverA, serverB, 25*time.Millisecond)
	fmt.Printf("  Result: %s | Elapsed: %v\n", res1, d1)

	// 2. Tail Latency Anomaly: Primary server hits 100ms GC pause / disk stall!
	fmt.Println("\n[2] Tail Latency Anomaly: Primary hits 100ms stall -> Request Hedging protects SLA:")
	serverA.isSlow.Store(true) // Simulating tail latency degradation

	res2, d2 := RequestHedge(ctx, serverA, serverB, 25*time.Millisecond)
	fmt.Printf("  Result: %s | Elapsed: %v (Saved from 100ms stall!)\n", res2, d2)

	// 3. Cascading Failure Defense via Context Timeout
	fmt.Println("\n[3] Cascading Failure Defense via Hard Context Deadlines:")
	serverB.isSlow.Store(true) // Both servers stall
	ctxTimeout, cancelTimeout := context.WithTimeout(context.Background(), 40*time.Millisecond)
	defer cancelTimeout()

	_, d3 := RequestHedge(ctxTimeout, serverA, serverB, 20*time.Millisecond)
	fmt.Printf("  Both servers stalled. Hard deadline aborted in %v, preventing thread pool exhaustion!\n", d3)

	fmt.Println("\n[SD3 Takeaway]: Synchronous calls must enforce strict context deadlines; Request Hedging neutralizes P99 tail latency spikes.")
}
