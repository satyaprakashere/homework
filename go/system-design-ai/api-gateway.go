//go:build ignore

package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): API GATEWAY ARCHITECTURE & RATE LIMITING
================================================================================
Key Topics Covered:
1. Core Responsibilities of an API Gateway:
   - Authentication & Authorization (API Key / Bearer Token inspection).
   - Rate Limiting (Token Bucket algorithm per IP / User).
   - Reverse Routing to Microservices.
   - Request Aggregation / BFF (Backend for Frontend): Fan-out to multiple
     microservices concurrently and return a composite response to mobile/web.
2. Token Bucket Algorithm:
   - Capacity: Max burst capacity (e.g. 5 tokens).
   - Refill Rate: Tokens added per second (e.g. 2 tokens/sec).
   - Smooth traffic pacing, handles bursts without starving callers.
================================================================================
*/

// TokenBucket implements per-client token bucket rate limiting
type TokenBucket struct {
	capacity   float64
	tokens     float64
	refillRate float64 // tokens per second
	lastRefill time.Time
	mu         sync.Mutex
}

func NewTokenBucket(capacity, refillRate float64) *TokenBucket {
	return &TokenBucket{
		capacity:   capacity,
		tokens:     capacity,
		refillRate: refillRate,
		lastRefill: time.Now(),
	}
}

func (tb *TokenBucket) Allow() bool {
	tb.mu.Lock()
	defer tb.mu.Unlock()

	now := time.Now()
	elapsed := now.Sub(tb.lastRefill).Seconds()
	tb.lastRefill = now

	// Refill tokens based on time elapsed
	tb.tokens += elapsed * tb.refillRate
	if tb.tokens > tb.capacity {
		tb.tokens = tb.capacity
	}

	if tb.tokens >= 1.0 {
		tb.tokens -= 1.0
		return true
	}
	return false
}

// APIGateway orchestrates routing, rate limiting, and BFF aggregation
type APIGateway struct {
	rateLimiters map[string]*TokenBucket
	apiKeys      map[string]string // Key -> UserID
	mu           sync.RWMutex
}

func NewAPIGateway() *APIGateway {
	return &APIGateway{
		rateLimiters: make(map[string]*TokenBucket),
		apiKeys: map[string]string{
			"sec-key-user-101": "user_101",
			"sec-key-user-202": "user_202",
		},
	}
}

func (gw *APIGateway) getLimiter(clientID string) *TokenBucket {
	gw.mu.Lock()
	defer gw.mu.Unlock()

	limiter, exists := gw.rateLimiters[clientID]
	if !exists {
		// Burst capacity = 3, refills at 2 tokens/sec
		limiter = NewTokenBucket(3.0, 2.0)
		gw.rateLimiters[clientID] = limiter
	}
	return limiter
}

func (gw *APIGateway) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 1. Authentication Layer
	apiKey := r.Header.Get("X-API-Key")
	gw.mu.RLock()
	userID, validKey := gw.apiKeys[apiKey]
	gw.mu.RUnlock()

	if !validKey {
		http.Error(w, `{"error": "Unauthorized: invalid or missing X-API-Key"}`, http.StatusUnauthorized)
		return
	}

	// 2. Rate Limiting Layer (Token Bucket)
	limiter := gw.getLimiter(userID)
	if !limiter.Allow() {
		w.Header().Set("Retry-After", "1")
		http.Error(w, `{"error": "Too Many Requests: rate limit exceeded"}`, http.StatusTooManyRequests)
		return
	}

	// 3. Routing & Aggregation Layer
	path := r.URL.Path
	switch {
	case strings.HasPrefix(path, "/api/v1/profile"):
		gw.handleProfileAggregation(w, userID)
	case strings.HasPrefix(path, "/api/v1/products"):
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`[{"id": 1, "name": "Laptop"}, {"id": 2, "name": "Monitor"}]`))
	default:
		http.NotFound(w, r)
	}
}

// handleProfileAggregation implements the BFF (Backend-For-Frontend) Aggregator Pattern
// Concurrently fetches User Info and Order History from different microservices
func (gw *APIGateway) handleProfileAggregation(w http.ResponseWriter, userID string) {
	type UserInfo struct {
		ID   string `json:"userId"`
		Name string `json:"name"`
	}
	type OrderInfo struct {
		TotalOrders int      `json:"totalOrders"`
		RecentItems []string `json:"recentItems"`
	}

	var user UserInfo
	var orders OrderInfo
	var wg sync.WaitGroup
	wg.Add(2)

	// Microservice A: User Service
	go func() {
		defer wg.Done()
		time.Sleep(10 * time.Millisecond) // Simulated RPC latency
		user = UserInfo{ID: userID, Name: "Prakash Deep"}
	}()

	// Microservice B: Order History Service
	go func() {
		defer wg.Done()
		time.Sleep(12 * time.Millisecond) // Simulated RPC latency
		orders = OrderInfo{TotalOrders: 42, RecentItems: []string{"Cloud Server", "SSD 2TB"}}
	}()

	wg.Wait()

	// Composite JSON response
	response := map[string]any{
		"profile": user,
		"orders":  orders,
		"servedAt": time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(response)
}

func main() {
	fmt.Println("=== SD3 API Gateway: Auth, Token Bucket Rate Limiting & BFF Aggregation ===")

	gw := NewAPIGateway()

	// 1. Test Authentication Validation
	fmt.Println("\n[1] Testing Authentication Middleware:")
	reqNoAuth := httptest.NewRequest("GET", "/api/v1/products", nil)
	recNoAuth := httptest.NewRecorder()
	gw.ServeHTTP(recNoAuth, reqNoAuth)
	fmt.Printf("  Missing API Key: Status %d | Body: %s\n", recNoAuth.Code, strings.TrimSpace(recNoAuth.Body.String()))

	// 2. Test BFF Aggregation (Composite Profile + Orders)
	fmt.Println("\n[2] Testing BFF (Backend-For-Frontend) Aggregation:")
	reqBFF := httptest.NewRequest("GET", "/api/v1/profile", nil)
	reqBFF.Header.Set("X-API-Key", "sec-key-user-101")
	recBFF := httptest.NewRecorder()
	start := time.Now()
	gw.ServeHTTP(recBFF, reqBFF)
	fmt.Printf("  Aggregated response in %v:\n  %s\n", time.Since(start), strings.TrimSpace(recBFF.Body.String()))

	// 3. Test Token Bucket Rate Limiting (Burst Capacity: 3)
	fmt.Println("[3] Testing Token Bucket Rate Limiting (Rapid fire 6 requests):")
	for i := 1; i <= 6; i++ {
		req := httptest.NewRequest("GET", "/api/v1/products", nil)
		req.Header.Set("X-API-Key", "sec-key-user-101")
		rec := httptest.NewRecorder()
		gw.ServeHTTP(rec, req)
		fmt.Printf("  Request #%d: Status %d (%s)\n", i, rec.Code, http.StatusText(rec.Code))
	}

	// 4. Wait for Token Bucket Refill
	fmt.Println("\n[4] Waiting 600ms for Token Bucket to refill...")
	time.Sleep(600 * time.Millisecond)
	reqRefill := httptest.NewRequest("GET", "/api/v1/products", nil)
	reqRefill.Header.Set("X-API-Key", "sec-key-user-101")
	recRefill := httptest.NewRecorder()
	gw.ServeHTTP(recRefill, reqRefill)
	fmt.Printf("  Post-refill Request: Status %d (%s)\n", recRefill.Code, http.StatusText(recRefill.Code))

	fmt.Println("\n[SD3 Takeaway]: API Gateway acts as single entry point for client apps, enforcing auth, rate limits, and coalescing microservice calls.")
}
