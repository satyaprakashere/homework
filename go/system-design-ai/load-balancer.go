//go:build ignore

package main

import (
	"context"
	"fmt"
	"hash/fnv"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): LOAD BALANCER (L4 vs L7) & BALANCING ALGORITHMS
================================================================================
Key Topics Covered:
1. Layer 4 (Transport) vs Layer 7 (Application) Load Balancing:
   - L4: High throughput packet forwarding based on IP+Port (e.g. AWS NLB, IPVS).
   - L7: Deep packet inspection (HTTP Path, Headers, Cookies) (e.g. AWS ALB, NGINX, Envoy).
2. Load Balancing Algorithms:
   - Round Robin
   - Weighted Round Robin
   - Least Connections (Dynamic balance based on active in-flight requests)
   - Consistent IP Hash (Sticky session affinity)
3. Active Health Checking & Failure Circuit Breaking.
4. Connection Draining (Graceful backend server deployment).

SD3 Architectural Comparison:
+-------------------+----------------------------+-----------------------------+
| Dimension         | L4 (Transport / NLB)       | L7 (Application / ALB/Envoy)|
+-------------------+----------------------------+-----------------------------+
| Inspection        | TCP/UDP 5-tuple only       | HTTP URI, Headers, Cookies  |
| TLS Termination   | Optional (Passthrough)     | Yes (Can inspect plaintext) |
| Throughput        | Millions of packets/sec    | Tens/hundreds of thousands  |
| Routing Rules     | Port-based only            | Path-based (/api/v1/orders) |
| Latency Overhead  | Microseconds               | Milliseconds                |
+-------------------+----------------------------+-----------------------------+
================================================================================
*/

type BackendServer struct {
	URL            string
	Weight         int
	ActiveConns    atomic.Int64
	TotalServed    atomic.Uint64
	Healthy        atomic.Bool
	Draining       atomic.Bool
	ConsecutiveErr atomic.Int32
}

func NewBackend(url string, weight int) *BackendServer {
	b := &BackendServer{
		URL:    url,
		Weight: weight,
	}
	b.Healthy.Store(true)
	return b
}

type LoadBalancer struct {
	backends []*BackendServer
	mu       sync.RWMutex
	rrIndex  atomic.Uint64
}

func NewLoadBalancer(backends []*BackendServer) *LoadBalancer {
	return &LoadBalancer{backends: backends}
}

// -----------------------------------------------------------------------------
// BALANCING ALGORITHMS
// -----------------------------------------------------------------------------

// 1. Round Robin
func (lb *LoadBalancer) NextRoundRobin() *BackendServer {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	alive := lb.getHealthyBackends()
	if len(alive) == 0 {
		return nil
	}
	idx := lb.rrIndex.Add(1) % uint64(len(alive))
	return alive[idx]
}

// 2. Weighted Round Robin
func (lb *LoadBalancer) NextWeightedRoundRobin() *BackendServer {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	alive := lb.getHealthyBackends()
	if len(alive) == 0 {
		return nil
	}

	totalWeight := 0
	for _, b := range alive {
		totalWeight += b.Weight
	}
	if totalWeight == 0 {
		return alive[0]
	}

	idx := lb.rrIndex.Add(1) % uint64(totalWeight)
	current := 0
	for _, b := range alive {
		current += b.Weight
		if int(idx) < current {
			return b
		}
	}
	return alive[0]
}

// 3. Least Connections: Routes to backend with lowest active in-flight requests
func (lb *LoadBalancer) NextLeastConnections() *BackendServer {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	alive := lb.getHealthyBackends()
	if len(alive) == 0 {
		return nil
	}

	var best *BackendServer
	var minConns int64 = 1<<62 - 1

	for _, b := range alive {
		conns := b.ActiveConns.Load()
		if conns < minConns {
			minConns = conns
			best = b
		}
	}
	return best
}

// 4. IP Hash: Guarantees same client IP reaches same backend (Session Affinity)
func (lb *LoadBalancer) NextIPHash(clientIP string) *BackendServer {
	lb.mu.RLock()
	defer lb.mu.RUnlock()

	alive := lb.getHealthyBackends()
	if len(alive) == 0 {
		return nil
	}

	h := fnv.New32a()
	h.Write([]byte(clientIP))
	idx := h.Sum32() % uint32(len(alive))
	return alive[idx]
}

func (lb *LoadBalancer) getHealthyBackends() []*BackendServer {
	var healthy []*BackendServer
	for _, b := range lb.backends {
		if b.Healthy.Load() && !b.Draining.Load() {
			healthy = append(healthy, b)
		}
	}
	return healthy
}

// ActiveHealthChecker runs synthetic probes and takes down failing nodes
func (lb *LoadBalancer) StartHealthChecker(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		for {
			select {
			case <-ctx.Done():
				ticker.Stop()
				return
			case <-ticker.C:
				lb.mu.RLock()
				for _, b := range lb.backends {
					// Simulate health check probe
					if b.ConsecutiveErr.Load() >= 3 {
						if b.Healthy.CompareAndSwap(true, false) {
							fmt.Printf("  [HEALTH CHECK CRITICAL] Marked %s UNHEALTHY (>= 3 errors)!\n", b.URL)
						}
					}
				}
				lb.mu.RUnlock()
			}
		}
	}()
}

func main() {
	fmt.Println("=== SD3 Load Balancer: Algorithms, Health Checking & Connection Tracking ===")

	b1 := NewBackend("http://app-worker-1:8080 (Weight: 1)", 1)
	b2 := NewBackend("http://app-worker-2:8080 (Weight: 2)", 2)
	b3 := NewBackend("http://app-worker-3:8080 (Weight: 3)", 3)

	lb := NewLoadBalancer([]*BackendServer{b1, b2, b3})

	// 1. Weighted Round Robin Distribution
	fmt.Println("\n[1] Testing Weighted Round Robin (Weights: 1, 2, 3):")
	wrrStats := make(map[string]int)
	for i := 0; i < 600; i++ {
		target := lb.NextWeightedRoundRobin()
		wrrStats[target.URL]++
	}
	for url, count := range wrrStats {
		fmt.Printf("  %s -> Received %d requests (%.1f%% of total)\n", url, count, float64(count)/6.0)
	}

	// 2. Least Connections Algorithm
	fmt.Println("\n[2] Testing Least Connections Algorithm:")
	// Simulate background load on b1 and b2
	b1.ActiveConns.Store(15) // busy
	b2.ActiveConns.Store(8)  // moderate
	b3.ActiveConns.Store(1)  // almost idle

	fmt.Printf("  Current Active Conns: b1: %d | b2: %d | b3: %d\n",
		b1.ActiveConns.Load(), b2.ActiveConns.Load(), b3.ActiveConns.Load())
	chosen := lb.NextLeastConnections()
	fmt.Printf("  Least Connections chose: %s (Active: %d)\n", chosen.URL, chosen.ActiveConns.Load())

	// 3. IP Hash Sticky Affinity
	fmt.Println("\n[3] Testing IP Hash Session Affinity:")
	ip1 := "203.0.113.19"
	ip2 := "198.51.100.42"
	for round := 1; round <= 3; round++ {
		t1 := lb.NextIPHash(ip1)
		t2 := lb.NextIPHash(ip2)
		fmt.Printf("  Round %d: Client %s -> %s | Client %s -> %s\n", round, ip1, t1.URL, ip2, t2.URL)
	}

	// 4. Dynamic Health Failure & Failover
	fmt.Println("\n[4] Simulating Backend Failure & Circuit Breaking:")
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	lb.StartHealthChecker(ctx, 20*time.Millisecond)

	// Simulate 3 consecutive 5xx errors on b3
	b3.ConsecutiveErr.Store(3)
	time.Sleep(50 * time.Millisecond) // wait for health check tick

	fmt.Println("  Routing next 10 requests via Round-Robin post-failure:")
	for i := 0; i < 6; i++ {
		target := lb.NextRoundRobin()
		fmt.Printf("    Request %d routed to: %s\n", i+1, target.URL)
	}

	fmt.Println("\n[SD3 Takeaway]: Weighted RR handles heterogeneous servers; Least Conns avoids queue buildup; IP Hash guarantees sticky state; Health checks protect SLAs.")
}
