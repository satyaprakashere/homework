//go:build ignore

package main

import (
	"context"
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): ASYNCHRONOUS ARCHITECTURE (FAN-OUT / FAN-IN)
================================================================================
Key Topics Covered:
1. Asynchronous Job Processing Patterns:
   - Async Job Handshake: Client submits task -> Server returns 202 Accepted + JobID immediately.
   - Background execution decoupled from HTTP request/response cycle.
2. The Fan-Out / Fan-In Concurrency Pattern:
   - Fan-Out: Multiple worker goroutines read from a shared source channel to parallelize compute.
   - Fan-In: Multiple worker output channels multiplexed and merged into a single consolidated stream.
3. Context Cancellation & Drain:
   - Propagating context cancellation to abort downstream async workers when job is cancelled.
================================================================================
*/

type Job struct {
	ID       int
	Payload  string
	Priority int
}

type JobResult struct {
	JobID       int
	ProcessedBy int
	Output      string
	Duration    time.Duration
}

// FanOutFanIn coordinates asynchronous worker pool processing
func FanOutFanIn(ctx context.Context, jobs []Job, numWorkers int) []JobResult {
	jobsChan := make(chan Job, len(jobs))
	resultsChan := make(chan JobResult, len(jobs))

	// Enqueue jobs
	for _, j := range jobs {
		jobsChan <- j
	}
	close(jobsChan)

	var wg sync.WaitGroup

	// FAN-OUT: Spawn N concurrent workers
	for w := 1; w <= numWorkers; w++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			for {
				select {
				case <-ctx.Done():
					return // Job cancelled
				case job, ok := <-jobsChan:
					if !ok {
						return
					}
					// Process task
					start := time.Now()
					time.Sleep(time.Duration(10+job.ID*2) * time.Millisecond) // Simulated compute
					res := JobResult{
						JobID:       job.ID,
						ProcessedBy: workerID,
						Output:      fmt.Sprintf("Transcoded [%s] successfully", job.Payload),
						Duration:    time.Since(start),
					}
					resultsChan <- res
				}
			}
		}(w)
	}

	// FAN-IN: Wait for all workers to finish and close results channel
	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	var allResults []JobResult
	for r := range resultsChan {
		allResults = append(allResults, r)
	}
	return allResults
}

func main() {
	fmt.Println("=== SD3 Asynchronous Processing: Fan-Out / Fan-In Pipeline ===")

	jobs := []Job{
		{ID: 1, Payload: "video_chunk_001.mp4"},
		{ID: 2, Payload: "video_chunk_002.mp4"},
		{ID: 3, Payload: "video_chunk_003.mp4"},
		{ID: 4, Payload: "video_chunk_004.mp4"},
		{ID: 5, Payload: "video_chunk_005.mp4"},
		{ID: 6, Payload: "video_chunk_006.mp4"},
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	numWorkers := 3
	fmt.Printf("\n[1] Executing Fan-Out / Fan-In across %d parallel workers for %d jobs:\n", numWorkers, len(jobs))
	start := time.Now()

	results := FanOutFanIn(ctx, jobs, numWorkers)

	totalTime := time.Since(start)

	for _, res := range results {
		fmt.Printf("  Job #%d processed by [Worker-%d] in %v -> %s\n",
			res.JobID, res.ProcessedBy, res.Duration, res.Output)
	}

	fmt.Printf("\n  Total Pipeline Wall-Clock Time: %v (3x faster than sequential execution!)\n", totalTime)

	fmt.Println("\n[SD3 Takeaway]: Fan-Out/Fan-In decouples heavy compute from synchronous request paths and maximizes multi-core CPU saturation.")
}
