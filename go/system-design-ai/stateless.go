//go:build ignore

package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync"
	"sync/atomic"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): STATELESS SERVICE ARCHITECTURE & HORIZONTAL SCALING
================================================================================
Key Topics Covered:
1. Stateless Architecture Principles:
   - Server holds ZERO client state in local process memory between requests.
   - All state externalized to high-speed shared stores (Redis, DynamoDB) or self-contained tokens (JWT).
   - Any client request can land on ANY server instance behind the load balancer interchangeably.
2. Advantages:
   - Effortless Horizontal Autoscaling: Spin up 50 pods during traffic surges, terminate 40 pods at night.
   - Zero-Downtime Rolling Deploys: Kill instance A while instance B handles traffic with zero session drops.
   - Chaos Resilience: If a server crashes, no active sessions or cart data are lost.
================================================================================
*/

// ExternalSessionStore simulates a shared Redis cluster for session externalization
type ExternalSessionStore struct {
	sessions map[string]string // SessionToken -> UserData JSON
	mu       sync.RWMutex
}

func NewExternalSessionStore() *ExternalSessionStore {
	return &ExternalSessionStore{sessions: make(map[string]string)}
}

func (s *ExternalSessionStore) Save(token, data string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.sessions[token] = data
}

func (s *ExternalSessionStore) Get(token string) (string, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	data, ok := s.sessions[token]
	return data, ok
}

// StatelessServerPod represents one disposable container pod in Kubernetes
type StatelessServerPod struct {
	PodName      string
	sessionStore *ExternalSessionStore
	requestCount atomic.Uint64
}

func (pod *StatelessServerPod) HandleRequest(w http.ResponseWriter, r *http.Request) {
	pod.requestCount.Add(1)

	sessionToken := r.Header.Get("X-Session-Token")
	if sessionToken == "" {
		http.Error(w, "Unauthorized: missing session token", http.StatusUnauthorized)
		return
	}

	// Fetch state from shared external store (NOT local memory!)
	data, exists := pod.sessionStore.Get(sessionToken)
	if !exists {
		http.Error(w, "Session expired", http.StatusUnauthorized)
		return
	}

	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(fmt.Sprintf(`{"servedBy": "%s", "data": %s}`, pod.PodName, data)))
}

func main() {
	fmt.Println("=== SD3 Stateless Architecture: Externalized Sessions & Pod Interchangeability ===")

	sharedStore := NewExternalSessionStore()

	// Populate user session in shared Redis store
	token := "sess_tok_9981"
	sharedStore.Save(token, `{"userId": "prakash", "cartItems": 3, "role": "admin"}`)

	// Spin up 3 identical stateless pods
	pod1 := &StatelessServerPod{PodName: "pod-app-7b9c-1", sessionStore: sharedStore}
	pod2 := &StatelessServerPod{PodName: "pod-app-7b9c-2", sessionStore: sharedStore}
	pod3 := &StatelessServerPod{PodName: "pod-app-7b9c-3", sessionStore: sharedStore}

	pods := []*StatelessServerPod{pod1, pod2, pod3}

	fmt.Println("\n[1] Dispatching consecutive requests to different pods (Demonstrating Interchangeability):")
	for i := 0; i < 3; i++ {
		targetPod := pods[i]
		req := httptest.NewRequest("GET", "/api/cart", nil)
		req.Header.Set("X-Session-Token", token)
		rec := httptest.NewRecorder()

		targetPod.HandleRequest(rec, req)
		fmt.Printf("  Request #%d routed to [%s]: Status %d -> %s\n",
			i+1, targetPod.PodName, rec.Code, rec.Body.String())
	}

	// Simulating Pod 1 crashing and being replaced by Pod 4
	fmt.Println("\n[2] Chaos Simulation: Pod 1 crashes! Pod 4 spawned in its place:")
	pod4 := &StatelessServerPod{PodName: "pod-app-7b9c-4", sessionStore: sharedStore}

	reqCrash := httptest.NewRequest("GET", "/api/cart", nil)
	reqCrash.Header.Set("X-Session-Token", token)
	recCrash := httptest.NewRecorder()
	pod4.HandleRequest(recCrash, reqCrash)
	fmt.Printf("  Client transparently served by newly created [%s] with ZERO session loss: %s\n",
		pod4.PodName, recCrash.Body.String())

	fmt.Println("\n[SD3 Takeaway]: Statelessness externalizes state to fast shared data layers, enabling instant pod autoscaling and zero-downtime deployments.")
}
