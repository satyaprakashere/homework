package main

import (
	"fmt"
	"net/http"
	"sync"
	"testing"
	"time"
)

func TestLoad(t *testing.T) {
	const (
		concurrency = 50
		requests    = 500
		url         = "http://localhost:9000/"
	)

	var wg sync.WaitGroup
	wg.Add(concurrency)

	start := time.Now()
	errCh := make(chan error, requests)
	results := make(chan time.Duration, requests)

	reqPerWorker := requests / concurrency

	for i := 0; i < concurrency; i++ {
		go func() {
			defer wg.Done()
			for j := 0; j < reqPerWorker; j++ {
				reqStart := time.Now()
				resp, err := http.Get(url)
				if err != nil {
					errCh <- err
					continue
				}
				results <- time.Since(reqStart)
				resp.Body.Close()
				if resp.StatusCode != http.StatusOK {
					errCh <- fmt.Errorf("unexpected status code: %d", resp.StatusCode)
				}
			}
		}()
	}

	wg.Wait()
	duration := time.Since(start)
	close(errCh)
	close(results)

	errCount := 0
	for range errCh {
		errCount++
	}

	var totalLatency time.Duration
	count := 0
	for l := range results {
		totalLatency += l
		count++
	}

	fmt.Printf("\n--- Load Test Results ---\n")
	fmt.Printf("Concurrency: %d\n", concurrency)
	fmt.Printf("Total Requests: %d\n", requests)
	fmt.Printf("Total Time: %v\n", duration)
	fmt.Printf("Requests/sec: %.2f\n", float64(count)/duration.Seconds())
	if count > 0 {
		fmt.Printf("Avg Latency: %v\n", totalLatency/time.Duration(count))
	}
	fmt.Printf("Errors: %d\n", errCount)
	fmt.Printf("-------------------------\n")

	if errCount > 0 {
		t.Logf("Encountered %d errors during load test", errCount)
	}
}
