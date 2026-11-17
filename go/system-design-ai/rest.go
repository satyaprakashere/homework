//go:build ignore

package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): REST API DESIGN, IDEMPOTENCY & PAGINATION
================================================================================
Key Topics Covered:
1. Idempotency Key Pattern:
   - Guarantees exactly-once execution semantics for non-idempotent operations (POST /orders, POST /payments).
   - In-flight lock state vs Completed state with cached response.
   - Prevents double-charging when network retries occur.
2. Keyset (Cursor-Based) vs Offset-Based Pagination:
   - Offset: SELECT * FROM orders LIMIT 20 OFFSET 100000 -> DB must scan and discard 100,000 rows! O(N) degradation.
   - Cursor: SELECT * FROM orders WHERE id > cursor_id ORDER BY id ASC LIMIT 20 -> O(1) index seek.
3. Proper REST Status Codes: 201 Created + Location header, 409 Conflict, 429 Too Many Requests.
================================================================================
*/

type IdempotencyState string

const (
	StateInFlight  IdempotencyState = "IN_FLIGHT"
	StateCompleted IdempotencyState = "COMPLETED"
)

type CachedResponse struct {
	State      IdempotencyState
	StatusCode int
	Body       string
	CreatedAt  time.Time
}

// PaymentService with Idempotency Key protection
type PaymentService struct {
	idempotencyStore map[string]*CachedResponse
	payments         map[string]int // PaymentID -> Amount
	mu               sync.Mutex
}

func NewPaymentService() *PaymentService {
	return &PaymentService{
		idempotencyStore: make(map[string]*CachedResponse),
		payments:         make(map[string]int),
	}
}

func (s *PaymentService) Charge(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
		return
	}

	idempotencyKey := r.Header.Get("Idempotency-Key")
	if idempotencyKey == "" {
		http.Error(w, `{"error": "Missing required Idempotency-Key header"}`, http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	cached, exists := s.idempotencyStore[idempotencyKey]
	if exists {
		if cached.State == StateInFlight {
			s.mu.Unlock()
			http.Error(w, `{"error": "Concurrent request in-flight for this idempotency key"}`, http.StatusConflict)
			return
		}
		// Return cached result: Customer is NEVER billed twice!
		s.mu.Unlock()
		fmt.Printf("  [IDEMPOTENT HIT] Replaying cached response for key: %s\n", idempotencyKey)
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache-Replay", "true")
		w.WriteHeader(cached.StatusCode)
		_, _ = w.Write([]byte(cached.Body))
		return
	}

	// Mark key as IN_FLIGHT
	s.idempotencyStore[idempotencyKey] = &CachedResponse{
		State:     StateInFlight,
		CreatedAt: time.Now(),
	}
	s.mu.Unlock()

	// Parse payload
	var payload struct {
		Amount int `json:"amount"`
	}
	_ = json.NewDecoder(r.Body).Decode(&payload)

	// Simulate payment gateway charging
	time.Sleep(10 * time.Millisecond)
	paymentID := fmt.Sprintf("pay_%d", time.Now().UnixNano())
	respBody := fmt.Sprintf(`{"paymentId": "%s", "status": "succeeded", "amount": %d}`, paymentID, payload.Amount)

	// Mark key as COMPLETED with cached response
	s.mu.Lock()
	s.payments[paymentID] = payload.Amount
	s.idempotencyStore[idempotencyKey] = &CachedResponse{
		State:      StateCompleted,
		StatusCode: http.StatusCreated,
		Body:       respBody,
		CreatedAt:  time.Now(),
	}
	s.mu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Location", "/v1/payments/"+paymentID)
	w.WriteHeader(http.StatusCreated)
	_, _ = w.Write([]byte(respBody))
}

// -----------------------------------------------------------------------------
// CURSOR-BASED PAGINATION
// -----------------------------------------------------------------------------

type Item struct {
	ID    int    `json:"id"`
	Title string `json:"title"`
}

type PaginatedResult struct {
	Data       []Item `json:"data"`
	NextCursor int    `json:"next_cursor"`
	HasMore    bool   `json:"has_more"`
}

type CatalogStore struct {
	items []Item
}

func (c *CatalogStore) QueryCursor(cursor, limit int) PaginatedResult {
	var result []Item
	startIdx := 0

	// Find starting index from cursor (O(1) in indexed DB, binary seek)
	for i, it := range c.items {
		if it.ID > cursor {
			startIdx = i
			break
		}
	}

	for i := startIdx; i < len(c.items) && len(result) < limit; i++ {
		result = append(result, c.items[i])
	}

	nextCursor := 0
	hasMore := false
	if len(result) > 0 {
		nextCursor = result[len(result)-1].ID
		hasMore = (startIdx + len(result)) < len(c.items)
	}

	return PaginatedResult{
		Data:       result,
		NextCursor: nextCursor,
		HasMore:    hasMore,
	}
}

func main() {
	fmt.Println("=== SD3 REST API: Idempotency Keys & Cursor-Based Pagination ===")

	paymentSvc := NewPaymentService()

	// 1. First POST with Idempotency Key
	fmt.Println("\n[1] Client POST /v1/payments (First Attempt):")
	key := "idemp-key-order-987"
	req1 := httptest.NewRequest("POST", "/v1/payments", strings.NewReader(`{"amount": 2500}`))
	req1.Header.Set("Idempotency-Key", key)
	rec1 := httptest.NewRecorder()
	paymentSvc.Charge(rec1, req1)
	fmt.Printf("  Status: %d | Location: %s\n", rec1.Code, rec1.Header().Get("Location"))
	fmt.Printf("  Body: %s\n", rec1.Body.String())

	// 2. Client Retries EXACT SAME POST (Network Timeout Simulation)
	fmt.Println("\n[2] Client Retries Same POST (Network Glitch Retry):")
	reqRetry := httptest.NewRequest("POST", "/v1/payments", strings.NewReader(`{"amount": 2500}`))
	reqRetry.Header.Set("Idempotency-Key", key)
	recRetry := httptest.NewRecorder()
	paymentSvc.Charge(recRetry, reqRetry)
	fmt.Printf("  Status: %d (Replayed! Total DB Payments: %d)\n", recRetry.Code, len(paymentSvc.payments))
	fmt.Printf("  Replayed Body: %s\n", recRetry.Body.String())

	// 3. Cursor-Based Pagination Demo
	fmt.Println("\n[3] Testing Cursor-Based Pagination (Limit: 3 per page):")
	var catalog []Item
	for i := 1; i <= 8; i++ {
		catalog = append(catalog, Item{ID: i * 10, Title: "Product #" + strconv.Itoa(i)})
	}
	store := &CatalogStore{items: catalog}

	cursor := 0
	page := 1
	for {
		res := store.QueryCursor(cursor, 3)
		fmt.Printf("  Page %d (Cursor %d) -> Fetched %d items (Next Cursor: %d, HasMore: %v)\n",
			page, cursor, len(res.Data), res.NextCursor, res.HasMore)
		if !res.HasMore {
			break
		}
		cursor = res.NextCursor
		page++
	}

	fmt.Println("\n[SD3 Takeaway]: Idempotency keys prevent double billing on network retries; Cursor pagination avoids O(N) DB offset performance cliffs.")
}
