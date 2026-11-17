//go:build ignore

package main

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): PROXY TAXONOMY & SIDECAR (SERVICE MESH)
================================================================================
Key Topics Covered:
1. Proxy Classification Taxonomy:
   - Forward Proxy: Protects/masks clients, egress compliance.
   - Reverse Proxy: Protects/masks server origin, ingress gateway.
   - Transparent Proxy: Intercepts traffic without client configuration (iptables/eBPF).
   - Sidecar Proxy (Envoy / Istio / Linkerd): Deployed 1:1 next to application container on localhost.
2. Service Mesh Sidecar Capabilities:
   - Ingress & Egress traffic interception.
   - Outlier Detection & Circuit Breaking (Closed -> Open -> Half-Open).
   - Latency Measurement & Golden Signals Telemetry (Traffic, Errors, Latency, Saturation).
   - Fault Injection (Chaos Engineering: latency injection, fault rate).
================================================================================
*/

type CircuitState string

const (
	StateClosed   CircuitState = "CLOSED"    // Normal operation: traffic flows through
	StateOpen     CircuitState = "OPEN"      // Breaker tripped: fast-fail without calling upstream
	StateHalfOpen CircuitState = "HALF_OPEN" // Trial recovery: allow canary probes through
)

// CircuitBreaker protects downstream callers from upstream cascading failures
type CircuitBreaker struct {
	state          CircuitState
	consecutiveErr int
	threshold      int
	cooldown       time.Duration
	lastStateChange time.Time
	mu             sync.Mutex
}

func NewCircuitBreaker(threshold int, cooldown time.Duration) *CircuitBreaker {
	return &CircuitBreaker{
		state:          StateClosed,
		threshold:      threshold,
		cooldown:       cooldown,
		lastStateChange: time.Now(),
	}
}

func (cb *CircuitBreaker) AllowRequest() bool {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	now := time.Now()
	if cb.state == StateOpen {
		if now.Sub(cb.lastStateChange) > cb.cooldown {
			cb.state = StateHalfOpen
			cb.lastStateChange = now
			fmt.Println("  [CIRCUIT BREAKER] Cooldown elapsed: Transitioned to HALF_OPEN (probing...)")
			return true
		}
		return false
	}
	return true
}

func (cb *CircuitBreaker) RecordSuccess() {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.consecutiveErr = 0
	if cb.state == StateHalfOpen {
		cb.state = StateClosed
		cb.lastStateChange = time.Now()
		fmt.Println("  [CIRCUIT BREAKER] Probe succeeded: Breaker RESET to CLOSED")
	}
}

func (cb *CircuitBreaker) RecordFailure() {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.consecutiveErr++
	if (cb.state == StateClosed && cb.consecutiveErr >= cb.threshold) || cb.state == StateHalfOpen {
		cb.state = StateOpen
		cb.lastStateChange = time.Now()
		fmt.Printf("  [CIRCUIT BREAKER CRITICAL] Threshold reached (%d errors): Breaker TRIPPED to OPEN!\n", cb.consecutiveErr)
	}
}

// SidecarProxy wraps outgoing/incoming calls for an application microservice
type SidecarProxy struct {
	ServiceName     string
	breaker         *CircuitBreaker
	requestsTotal   atomic.Uint64
	errorsTotal     atomic.Uint64
	latencySumMs    atomic.Int64
}

func NewSidecarProxy(name string) *SidecarProxy {
	return &SidecarProxy{
		ServiceName: name,
		breaker:     NewCircuitBreaker(3, 50*time.Millisecond),
	}
}

// InterceptEgress wraps an outbound RPC with circuit breaking, telemetry, and chaos injection
func (sp *SidecarProxy) InterceptEgress(ctx context.Context, targetService string, rpcCall func() error) error {
	sp.requestsTotal.Add(1)

	// 1. Check Circuit Breaker
	if !sp.breaker.AllowRequest() {
		sp.errorsTotal.Add(1)
		return fmt.Errorf("circuit breaker OPEN: fast-failing call to %s", targetService)
	}

	start := time.Now()

	// 2. Execute target call
	err := rpcCall()

	elapsed := time.Since(start).Milliseconds()
	sp.latencySumMs.Add(elapsed)

	// 3. Update Breaker State
	if err != nil {
		sp.errorsTotal.Add(1)
		sp.breaker.RecordFailure()
		return err
	}

	sp.breaker.RecordSuccess()
	return nil
}

func (sp *SidecarProxy) Stats() string {
	reqs := sp.requestsTotal.Load()
	errs := sp.errorsTotal.Load()
	avgLatency := float64(0)
	if reqs > 0 {
		avgLatency = float64(sp.latencySumMs.Load()) / float64(reqs)
	}
	return fmt.Sprintf("Service: %s | Total: %d | Errors: %d | AvgLatency: %.2fms",
		sp.ServiceName, reqs, errs, avgLatency)
}

func main() {
	fmt.Println("=== SD3 Sidecar Proxy (Service Mesh / Envoy Pattern) ===")

	sidecar := NewSidecarProxy("order-service-sidecar")
	ctx := context.Background()

	// Target downstream service: "payment-service"
	// Simulating unhealthy service that fails
	targetDownstream := func(shouldFail bool) func() error {
		return func() error {
			time.Sleep(5 * time.Millisecond)
			if shouldFail {
				return fmt.Errorf("500 Internal Server Error: payment database timeout")
			}
			return nil
		}
	}

	// 1. Normal successful calls
	fmt.Println("\n[1] Normal Outbound RPCs through Sidecar:")
	for i := 1; i <= 3; i++ {
		err := sidecar.InterceptEgress(ctx, "payment-service", targetDownstream(false))
		fmt.Printf("  Call %d: Success (Err: %v)\n", i, err)
	}

	// 2. Downstream begins failing -> Trip Circuit Breaker
	fmt.Println("\n[2] Downstream Service Outage -> Tripping Circuit Breaker:")
	for i := 1; i <= 4; i++ {
		err := sidecar.InterceptEgress(ctx, "payment-service", targetDownstream(true))
		fmt.Printf("  Call %d: Result -> %v\n", i, err)
	}

	// 3. Immediate subsequent call -> Fast-failed by breaker
	fmt.Println("\n[3] Breaker in OPEN State (Fast Fail Without Hitting Network):")
	start := time.Now()
	err := sidecar.InterceptEgress(ctx, "payment-service", targetDownstream(true))
	fmt.Printf("  Fast-fail returned: %v in %v (Zero network wasted!)\n", err, time.Since(start))

	// 4. Wait for Cooldown -> Half-Open state -> Recovery
	fmt.Println("\n[4] Waiting 60ms for Cooldown -> Probing Recovery in HALF_OPEN:")
	time.Sleep(60 * time.Millisecond)

	// Payment service recovers
	err = sidecar.InterceptEgress(ctx, "payment-service", targetDownstream(false))
	fmt.Printf("  Probe Call Result: %v (Breaker recovered to CLOSED)\n", err)

	fmt.Println("\n[5] Sidecar Telemetry & Metrics:")
	fmt.Printf("  %s\n", sidecar.Stats())

	fmt.Println("\n[SD3 Takeaway]: Sidecar proxies abstract cross-cutting concerns (retries, timeouts, circuit breaking, mTLS, telemetry) outside the application code.")
}
