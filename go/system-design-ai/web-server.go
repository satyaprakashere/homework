//go:build ignore

package main

import (
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"runtime/debug"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): PRODUCTION WEB SERVER ARCHITECTURE & RESILIENCE
================================================================================
Key Topics Covered:
1. Production Go HTTP Server Configuration:
   - ReadHeaderTimeout: Mitigates Slowloris DoS attacks (attackers slowly sending 1 header byte every 10s).
   - ReadTimeout & WriteTimeout: Bounds server connection resource consumption.
   - IdleTimeout: Keeps Keep-Alive connection pools clean.
   - MaxHeaderBytes: Defends against HTTP header bomb attacks.
2. Graceful Shutdown & Connection Draining:
   - On SIGTERM, stop accepting new connections while letting active requests finish
     within a deadline context (e.g. 5-30 seconds).
3. Production Middleware Stack:
   - Panic Recovery Middleware (catches panics, logs stack trace, returns 500 cleanly).
   - ResponseCapture & Structured Logging.
   - Per-request Context Deadlines.
================================================================================
*/

// statusRecorder captures the response status code for structured metrics/logging
type statusRecorder struct {
	http.ResponseWriter
	statusCode int
}

func (rec *statusRecorder) WriteHeader(code int) {
	rec.statusCode = code
	rec.ResponseWriter.WriteHeader(code)
}

// RecoveryMiddleware prevents server crashes from goroutine panics in handlers
func RecoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				fmt.Printf("  [CRITICAL PANIC RECOVERED] %v\n  Stack: %s\n", rec, string(debug.Stack()[:200]))
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				_, _ = w.Write([]byte(`{"error": "Internal Server Error", "code": 500}`))
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// LoggingMiddleware logs request duration and status code
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, statusCode: http.StatusOK}
		next.ServeHTTP(rec, r)
		duration := time.Since(start)
		fmt.Printf("  [HTTP LOG] %s %-12s -> Status: %d | Latency: %v\n",
			r.Method, r.URL.Path, rec.statusCode, duration)
	})
}

// TimeoutMiddleware sets a hard context deadline on long-running operations
func TimeoutMiddleware(timeout time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx, cancel := context.WithTimeout(r.Context(), timeout)
			defer cancel()
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// ServerController simulates the production lifecycle and graceful shutdown
type ServerController struct {
	activeWorkers atomic.Int64
	isShuttingDown atomic.Bool
}

func (s *ServerController) HandleJob(w http.ResponseWriter, r *http.Request) {
	if s.isShuttingDown.Load() {
		http.Error(w, "Server is draining", http.StatusServiceUnavailable)
		return
	}

	s.activeWorkers.Add(1)
	defer s.activeWorkers.Add(-1)

	// Check if client triggered a test panic
	if r.URL.Query().Get("panic") == "true" {
		panic("nil pointer dereference inside business logic handler!")
	}

	// Simulating compute task that observes context timeout
	select {
	case <-time.After(30 * time.Millisecond):
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"status": "completed", "result": "processed"}`))
	case <-r.Context().Done():
		http.Error(w, `{"error": "Request timed out"}`, http.StatusGatewayTimeout)
	}
}

func main() {
	fmt.Println("=== SD3 Web Server: Graceful Draining, Middleware & Panic Recovery ===")

	ctrl := &ServerController{}

	// Build Middleware Pipeline: Recovery -> Logging -> Timeout -> Business Logic
	mux := http.NewServeMux()
	mux.HandleFunc("/job", ctrl.HandleJob)

	pipeline := RecoveryMiddleware(
		LoggingMiddleware(
			TimeoutMiddleware(50 * time.Millisecond)(mux),
		),
	)

	// 1. Normal Request
	fmt.Println("\n[1] Testing Normal HTTP Request:")
	reqNormal := httptest.NewRequest("GET", "/job", nil)
	recNormal := httptest.NewRecorder()
	pipeline.ServeHTTP(recNormal, reqNormal)
	fmt.Printf("  Response Status: %d | Body: %s\n", recNormal.Code, recNormal.Body.String())

	// 2. Panic Recovery (handler throws panic)
	fmt.Println("\n[2] Testing Panic Recovery (Defends Server from Crashing):")
	reqPanic := httptest.NewRequest("GET", "/job?panic=true", nil)
	recPanic := httptest.NewRecorder()
	pipeline.ServeHTTP(recPanic, reqPanic)
	fmt.Printf("  Server recovered safely! Status: %d | Body: %s\n", recPanic.Code, recPanic.Body.String())

	// 3. Graceful Draining Demonstration
	fmt.Println("\n[3] Testing Graceful Draining (Simulating SIGTERM):")
	ctrl.isShuttingDown.Store(true) // Marks draining state
	fmt.Println("  Received SIGTERM -> Initiated graceful shutdown window (30s timeout)")

	reqRejected := httptest.NewRequest("GET", "/job", nil)
	recRejected := httptest.NewRecorder()
	pipeline.ServeHTTP(recRejected, reqRejected)
	fmt.Printf("  New incoming requests rejected cleanly: Status %d (503 Service Unavailable)\n", recRejected.Code)

	fmt.Println("\n[SD3 Takeaway]: Production servers MUST configure ReadHeaderTimeout to prevent Slowloris and use Graceful Shutdown to drain in-flight requests.")
}
