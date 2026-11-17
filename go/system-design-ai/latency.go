//go:build ignore

package main

import (
	"fmt"
	"math"
	"math/rand"
	"sort"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): LATENCY ANALYSIS, PERCENTILES & TAIL AMPLIFICATION
================================================================================
Key Topics Covered:
1. Why Average (Mean) Latency is a Dangerous Lie:
   - Outliers are hidden by the vast majority of fast queries.
   - SLAs and SLOs MUST always be defined in Percentiles: P50 (median), P95, P99, P99.9.
2. The Mathematics of Tail Latency Amplification:
   - Consider a page request that fans out to N backend services in parallel.
   - If each backend service has a 99th percentile latency (1% probability of taking > 1s),
     the probability that the USER experiences a slow response is:
     P(slow) = 1 - (1 - p)^N
     For N = 100 services and p = 0.01:
     P(slow) = 1 - (0.99)^100 = 63.4%!
     A 1% backend flaw ruins the experience for 63.4% of all end users!
3. Mitigation Strategies:
   - Request Hedging (Dean & Barroso).
   - Setting aggressive timeout budgets.
   - Circuit breaking sluggish outlier nodes.
================================================================================
*/

// LatencyTracker collects raw latencies and computes accurate percentiles
type LatencyTracker struct {
	samples []time.Duration
}

func (lt *LatencyTracker) Record(d time.Duration) {
	lt.samples = append(lt.samples, d)
}

func (lt *LatencyTracker) ComputePercentiles() (p50, p90, p99, p999 time.Duration, mean time.Duration) {
	if len(lt.samples) == 0 {
		return
	}

	sort.Slice(lt.samples, func(i, j int) bool {
		return lt.samples[i] < lt.samples[j]
	})

	var total time.Duration
	for _, s := range lt.samples {
		total += s
	}
	mean = total / time.Duration(len(lt.samples))

	n := len(lt.samples)
	p50 = lt.samples[int(float64(n)*0.50)]
	p90 = lt.samples[int(float64(n)*0.90)]
	p99 = lt.samples[int(float64(n)*0.99)]
	p999 = lt.samples[int(float64(n)*0.999)]
	return
}

func main() {
	fmt.Println("=== SD3 Latency Engineering: Percentiles & Tail Amplification Math ===")

	tracker := &LatencyTracker{}

	// 1. Simulate 10,000 backend RPC requests with a heavy tail
	// 95% of requests take 2ms-5ms. 4% take 15ms-25ms. 1% take 200ms-500ms (GC/disk pauses)
	for i := 0; i < 10000; i++ {
		r := rand.Float64()
		var lat time.Duration
		if r < 0.95 {
			lat = time.Duration(2000+rand.Intn(3000)) * time.Microsecond // 2-5ms
		} else if r < 0.99 {
			lat = time.Duration(15000+rand.Intn(10000)) * time.Microsecond // 15-25ms
		} else {
			lat = time.Duration(200000+rand.Intn(300000)) * time.Microsecond // 200-500ms (Tail spike!)
		}
		tracker.Record(lat)
	}

	p50, p90, p99, p999, mean := tracker.ComputePercentiles()

	fmt.Println("\n[1] Comparing Mean vs Percentiles across 10,000 requests:")
	fmt.Printf("  Mean (Average) Latency : %v (Looks deceptive!)\n", mean)
	fmt.Printf("  P50 (Median) Latency   : %v\n", p50)
	fmt.Printf("  P90 Latency            : %v\n", p90)
	fmt.Printf("  P99 Latency            : %v\n", p99)
	fmt.Printf("  P99.9 Latency          : %v (The critical tail!)\n", p999)

	// 2. Tail Latency Amplification Simulation
	fmt.Println("\n[2] The Dean & Barroso Tail Amplification Formula:")
	fmt.Println("  Formula: P(User Slow) = 1 - (1 - P_slow)^N")

	subservices := []int{1, 10, 50, 100, 200}
	pSlowSingle := 0.01 // 1% slow backend rate (P99)

	for _, n := range subservices {
		pUserSlow := 1.0 - math.Pow(1.0-pSlowSingle, float64(n))
		fmt.Printf("  Fan-out to %3d sub-services -> %.1f%% of overall user requests experience slow tail latency!\n",
			n, pUserSlow*100.0)
	}

	fmt.Println("\n[SD3 Takeaway]: At microservice scale, tail latency compounds exponentially; system designs must employ request hedging and deadline propagation to defend SLOs.")
}
