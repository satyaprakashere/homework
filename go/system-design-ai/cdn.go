//go:build ignore

package main

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): CONTENT DELIVERY NETWORK (CDN) ARCHITECTURE
================================================================================
Key Topics Covered:
1. Multi-Tier CDN Topology:
   - Edge PoP (Point of Presence) -> Origin Shield -> Origin Server.
   - Solves Origin Stampede when hundreds of global PoPs cold-start simultaneously.
2. Cache-Control Headers & Semantics:
   - max-age vs s-maxage (Browser cache vs Shared CDN cache).
   - stale-while-revalidate: Zero-latency serving of stale assets while background
     revalidation occurs asynchronously.
3. Conditional Requests (304 Not Modified):
   - ETag generation & If-None-Match header matching.
   - Eliminates bandwidth waste for unchanged assets.
4. Pull CDN vs Push CDN trade-offs.

SD3 Interview Gold:
- Question: "What is an Origin Shield and why is it essential at hyper-scale?"
  Answer:
  Cloudflare / Fastly have 300+ PoPs worldwide.
  If a popular news event breaks or live stream begins, without an Origin Shield,
  all 300 PoPs experience a cache miss concurrently, blasting the Origin database
  with 300 massive parallel requests.
  The Origin Shield acts as a regional aggregator cache: 300 PoPs query 2 Origin Shields,
  and only 1 request ever reaches the Origin data center.
================================================================================
*/

// HTTPResponse represents a cached HTTP response
type HTTPResponse struct {
	StatusCode int
	Body       string
	Headers    map[string]string
	ETag       string
	FetchedAt  time.Time
	MaxAge     time.Duration
	StaleTTL   time.Duration // stale-while-revalidate window
}

func (r *HTTPResponse) IsFresh() bool {
	return time.Since(r.FetchedAt) < r.MaxAge
}

func (r *HTTPResponse) CanServeStale() bool {
	age := time.Since(r.FetchedAt)
	return age >= r.MaxAge && age < (r.MaxAge+r.StaleTTL)
}

// OriginServer simulates the central application datacenter
type OriginServer struct {
	requestCount atomic.Uint64
	content      map[string]string
	mu           sync.RWMutex
}

func NewOriginServer() *OriginServer {
	return &OriginServer{
		content: map[string]string{
			"/app.js": "console.log('App v1.0.0 initialized');",
		},
	}
}

func (o *OriginServer) Fetch(path, ifNoneMatch string) (HTTPResponse, bool) {
	o.requestCount.Add(1)
	time.Sleep(50 * time.Millisecond) // Simulating slow cross-continental WAN latency

	o.mu.RLock()
	body, exists := o.content[path]
	o.mu.RUnlock()

	if !exists {
		return HTTPResponse{StatusCode: 404, Body: "Not Found"}, false
	}

	// Compute ETag
	hash := sha256.Sum256([]byte(body))
	etag := `"` + hex.EncodeToString(hash[:8]) + `"`

	// 304 Not Modified Check!
	if ifNoneMatch == etag {
		return HTTPResponse{
			StatusCode: 304,
			ETag:       etag,
			Headers: map[string]string{
				"ETag":          etag,
				"Cache-Control": "public, s-maxage=100, stale-while-revalidate=50",
			},
		}, true
	}

	return HTTPResponse{
		StatusCode: 200,
		Body:       body,
		ETag:       etag,
		FetchedAt:  time.Now(),
		MaxAge:     100 * time.Millisecond,
		StaleTTL:   100 * time.Millisecond,
		Headers: map[string]string{
			"Content-Type":  "application/javascript",
			"ETag":          etag,
			"Cache-Control": "public, s-maxage=100, stale-while-revalidate=50",
		},
	}, false
}

func (o *OriginServer) UpdateContent(path, newBody string) {
	o.mu.Lock()
	defer o.mu.Unlock()
	o.content[path] = newBody
}

// OriginShield sits between Edge PoPs and Origin to consolidate requests
type OriginShield struct {
	origin *OriginServer
	cache  map[string]HTTPResponse
	mu     sync.RWMutex
}

func NewOriginShield(origin *OriginServer) *OriginShield {
	return &OriginShield{
		origin: origin,
		cache:  make(map[string]HTTPResponse),
	}
}

func (s *OriginShield) Get(path string) HTTPResponse {
	s.mu.RLock()
	resp, found := s.cache[path]
	s.mu.RUnlock()

	if found && resp.IsFresh() {
		return resp
	}

	// Fetch from Origin and cache in Shield
	s.mu.Lock()
	defer s.mu.Unlock()

	// Double-check under lock
	if resp, found := s.cache[path]; found && resp.IsFresh() {
		return resp
	}

	fresh, _ := s.origin.Fetch(path, resp.ETag)
	if fresh.StatusCode == 304 {
		// Revalidate existing cached response
		resp.FetchedAt = time.Now()
		s.cache[path] = resp
		return resp
	}

	s.cache[path] = fresh
	return fresh
}

// EdgePoP simulates a local CDN Edge node serving end users
type EdgePoP struct {
	Region string
	shield *OriginShield
	cache  map[string]HTTPResponse
	mu     sync.RWMutex
}

func NewEdgePoP(region string, shield *OriginShield) *EdgePoP {
	return &EdgePoP{
		Region: region,
		shield: shield,
		cache:  make(map[string]HTTPResponse),
	}
}

// ServeRequest handles client HTTP request with stale-while-revalidate support
func (pop *EdgePoP) ServeRequest(path string, clientETag string) (HTTPResponse, string) {
	pop.mu.RLock()
	cached, found := pop.cache[path]
	pop.mu.RUnlock()

	// 1. Fresh Cache Hit at Edge
	if found && cached.IsFresh() {
		if clientETag == cached.ETag {
			return HTTPResponse{StatusCode: 304, ETag: cached.ETag}, "EDGE_CACHE_HIT (304 Not Modified)"
		}
		return cached, "EDGE_CACHE_HIT (200 OK)"
	}

	// 2. Stale-While-Revalidate: Return stale payload instantly, refresh in background!
	if found && cached.CanServeStale() {
		go func() {
			fresh := pop.shield.Get(path)
			pop.mu.Lock()
			pop.cache[path] = fresh
			pop.mu.Unlock()
		}()
		return cached, "EDGE_STALE_WHILE_REVALIDATE (Instant Serving + Background Async Refresh)"
	}

	// 3. Cache Miss: Pull through Origin Shield
	fresh := pop.shield.Get(path)
	pop.mu.Lock()
	pop.cache[path] = fresh
	pop.mu.Unlock()

	return fresh, "EDGE_CACHE_MISS -> ORIGIN_SHIELD_PULL"
}

func main() {
	fmt.Println("=== SD3 CDN: Edge PoP, Origin Shield & Stale-While-Revalidate ===")

	origin := NewOriginServer()
	shield := NewOriginShield(origin)

	popLondon := NewEdgePoP("London", shield)
	popTokyo := NewEdgePoP("Tokyo", shield)
	popSydney := NewEdgePoP("Sydney", shield)

	path := "/app.js"

	// 1. Cold Start: 3 different PoPs requesting the same file
	fmt.Println("\n[1] Cold Start Request across 3 Global Edge PoPs:")

	start := time.Now()
	_, source1 := popLondon.ServeRequest(path, "")
	fmt.Printf("  London: %s (Latency: %v)\n", source1, time.Since(start))

	start = time.Now()
	_, source2 := popTokyo.ServeRequest(path, "")
	fmt.Printf("  Tokyo : %s (Latency: %v - Shields origin!)\n", source2, time.Since(start))

	start = time.Now()
	_, source3 := popSydney.ServeRequest(path, "")
	fmt.Printf("  Sydney: %s (Latency: %v - Shields origin!)\n", source3, time.Since(start))

	fmt.Printf("  -> Total queries that reached Origin Server: %d (Origin Shield collapsed them!)\n", origin.requestCount.Load())

	// 2. Conditional 304 Not Modified
	fmt.Println("\n[2] Testing Conditional 304 Not Modified (Zero Bandwidth Body):")
	etag := `"95b06d48386dd264"` // client cached etag
	cachedResp, source4 := popLondon.ServeRequest(path, etag)
	fmt.Printf("  Client conditional request with ETag: Status: %d | Source: %s\n", cachedResp.StatusCode, source4)

	// 3. Stale-While-Revalidate Demonstration
	fmt.Println("\n[3] Testing Stale-While-Revalidate (Zero User Latency on Expiry):")
	fmt.Println("  Waiting 110ms for cache to become slightly stale...")
	time.Sleep(110 * time.Millisecond)

	start = time.Now()
	staleResp, source5 := popLondon.ServeRequest(path, "")
	fmt.Printf("  Request served: %s\n", source5)
	fmt.Printf("  User received payload in: %v (Stale data returned instantly without blocking on WAN)\n", time.Since(start))
	_ = staleResp

	// Wait for background revalidation
	time.Sleep(70 * time.Millisecond)
	freshResp, source6 := popLondon.ServeRequest(path, "")
	fmt.Printf("  Subsequent request now has freshly revalidated data: %s\n", source6)
	_ = freshResp

	fmt.Println("\n[SD3 Takeaway]: CDNs reduce TTFB (Time to First Byte) by terminating TCP/TLS at the edge; Origin Shields protect the source.")
}
