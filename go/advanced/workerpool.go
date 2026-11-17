package main

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"sync"
	"time"
)

type JobResult struct {
	ID    int
	Value string
	Err   error
}

// worker processes jobs from the channel until the context is cancelled.
func worker(ctx context.Context, id int, jobs <-chan int, results chan<- JobResult, wg *sync.WaitGroup) {
	defer wg.Done()
	for job := range jobs {
		select {
		case <-ctx.Done():
			results <- JobResult{ID: job, Err: ctx.Err()}
			return
		default:
			// Simulate processing time
			time.Sleep(time.Duration(rand.Intn(500)) * time.Millisecond)
			if rand.Float32() < 0.2 { // 20% chance of failure
				results <- JobResult{ID: job, Err: errors.New("random failure")}
			} else {
				results <- JobResult{ID: job, Value: fmt.Sprintf("Processed %d by worker %d", job, id)}
			}
		}
	}
}

func RunWorkerPoolDemo() {
	fmt.Println("\n--- 3. Advanced Worker Pool Demo ---")
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	numWorkers := 3
	numJobs := 10
	jobs := make(chan int, numJobs)
	results := make(chan JobResult, numJobs)
	var wg sync.WaitGroup

	// 1. Spawn workers
	for w := 1; w <= numWorkers; w++ {
		wg.Add(1)
		go worker(ctx, w, jobs, results, &wg)
	}

	// 2. Feed jobs
	for j := 1; j <= numJobs; j++ {
		jobs <- j
	}
	close(jobs)

	// 3. Close results channel once all workers are done
	go func() {
		wg.Wait()
		close(results)
	}()

	// 4. Collect results
	for res := range results {
		if res.Err != nil {
			fmt.Printf("Job %d failed: %v\n", res.ID, res.Err)
		} else {
			fmt.Printf("Job %d: %s\n", res.ID, res.Value)
		}
	}
}
