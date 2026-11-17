//go:build ignore

package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"math"
	"math/rand"
	"net"
	"net/http"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): RESILIENT HTTP CLIENT & EXPONENTIAL BACKOFF
================================================================================
Key Topics Covered:
1. Go http.Client Production Pitfalls:
   - Default http.Client has NO timeout (can hang indefinitely, leaking goroutines).
   - Default http.Transport has MaxIdleConnsPerHost = 2! Under microservice traffic,
     98% of connections are aggressively torn down, causing ephemeral port exhaustion (TIME_WAIT).
2. Production http.Transport Tuning:
   - MaxIdleConns & MaxIdleConnsPerHost (e.g. 100).
   - IdleConnTimeout (e.g. 90s).
   - DialContext timeout & TLSHandshakeTimeout.
3. Exponential Backoff with Full Jitter:
   - Backoff = Min(MaxWait, BaseWait * 2^attempt)
   - Sleep = Random(0, Backoff)
   - Full Jitter prevents retry synchrony where 10,000 failing clients all retry at the exact same second!
================================================================================
*/

// ResilientHTTPClient encapsulates configured transport, retries, and backoff
type ResilientHTTPClient struct {
	client     *http.Client
	maxRetries int
	baseWait   time.Duration
	maxWait    time.Duration
}

func NewResilientHTTPClient(maxRetries int) *ResilientHTTPClient {
	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   5 * time.Second,
			KeepAlive: 30 * time.Second,
		}).DialContext,
		MaxIdleConns:        500,
		MaxIdleConnsPerHost: 100, // CRITICAL: Go default of 2 will kill throughput
		IdleConnTimeout:     90 * time.Second,
		TLSHandshakeTimeout: 5 * time.Second,
		ResponseHeaderTimeout: 5 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}

	return &ResilientHTTPClient{
		client: &http.Client{
			Transport: transport,
			Timeout:   10 * time.Second, // Global request budget
		},
		maxRetries: maxRetries,
		baseWait:   20 * time.Millisecond,
		maxWait:    500 * time.Millisecond,
	}
}

// computeJitter calculates Exponential Backoff with Full Jitter
func (c *ResilientHTTPClient) computeJitter(attempt int) time.Duration {
	// multiplier: 2^attempt
	multiplier := math.Pow(2, float64(attempt))
	backoff := float64(c.baseWait) * multiplier
	if backoff > float64(c.maxWait) {
		backoff = float64(c.maxWait)
	}
	// Full Jitter: uniformly distributed between 0 and backoff
	jittered := rand.Float64() * backoff
	return time.Duration(jittered)
}

// DoWithRetry executes the request with retry logic
func (c *ResilientHTTPClient) DoWithRetry(ctx context.Context, fn func() (*http.Response, error)) (*http.Response, error) {
	var resp *http.Response
	var err error

	for attempt := 0; attempt <= c.maxRetries; attempt++ {
		// Execute call
		resp, err = fn()

		// Success check: 2xx or 3xx status
		if err == nil && resp.StatusCode < 500 {
			return resp, nil
		}

		// Don't sleep after the final failed attempt
		if attempt == c.maxRetries {
			break
		}

		// Calculate jittered backoff
		sleepDuration := c.computeJitter(attempt)
		fmt.Printf("  [RETRY BACKOFF] Attempt #%d failed (Status: %s). Backing off for %v (Full Jitter)...\n",
			attempt+1, http.StatusText(statusCode(resp, err)), sleepDuration)

		select {
		case <-time.After(sleepDuration):
		case <-ctx.Done():
			return nil, ctx.Err()
		}
	}

	return resp, err
}

func statusCode(resp *http.Response, err error) int {
	if resp != nil {
		return resp.StatusCode
	}
	return http.StatusServiceUnavailable
}

// FlakyTransport simulates an upstream server that fails 2 times with 503 before succeeding
type FlakyTransport struct {
	attemptCount atomic.Int32
}

func (t *FlakyTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	curr := t.attemptCount.Add(1)
	if curr <= 2 {
		return &http.Response{
			StatusCode: http.StatusServiceUnavailable,
			Status:     "503 Service Unavailable",
			Body:       io.NopCloser(bytes.NewBufferString(`{"error": "overloaded"}`)),
			Header:     make(http.Header),
		}, nil
	}

	// 3rd attempt succeeds!
	return &http.Response{
		StatusCode: http.StatusOK,
		Status:     "200 OK",
		Body:       io.NopCloser(bytes.NewBufferString(`{"status": "success", "data": "order_confirmed"}`)),
		Header:     make(http.Header),
	}, nil
}

func main() {
	fmt.Println("=== SD3 Resilient HTTP Client: Pool Tuning & Exponential Jitter ===")

	client := NewResilientHTTPClient(3)
	flaky := &FlakyTransport{}
	client.client.Transport = flaky

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	fmt.Println("\n[1] Executing Request against Flaky Upstream (Fails 2x with 503, succeeds on 3rd):")
	start := time.Now()

	resp, err := client.DoWithRetry(ctx, func() (*http.Response, error) {
		req, _ := http.NewRequestWithContext(ctx, "POST", "http://internal.checkout.api", nil)
		return client.client.Do(req)
	})

	if err != nil {
		fmt.Printf("  Final Error: %v\n", err)
	} else {
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)
		fmt.Printf("  Final Success! Status: %d (%s) in %v\n", resp.StatusCode, resp.Status, time.Since(start))
		fmt.Printf("  Response Body: %s\n", string(body))
	}

	fmt.Println("\n[SD3 Takeaway]: Tuning MaxIdleConnsPerHost avoids socket exhaustion; Exponential Backoff with Full Jitter protects recovering servers from retry storms.")
}