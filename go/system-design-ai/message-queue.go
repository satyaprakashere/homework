//go:build ignore

package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): MESSAGE QUEUES, DLQ & CONSUMER GROUPS
================================================================================
Key Topics Covered:
1. Message Queue Architectures:
   - Competing Consumers (RabbitMQ / SQS): Messages load-balanced among worker pool.
   - Partitioned Event Streaming (Kafka / Kinesis): Ordered partitioned log, consumer group offset tracking.
2. Delivery Semantics & Idempotency:
   - At-Least-Once Delivery: Inherent in distributed networks. Requires consumers to be Idempotent
     (using deduplication stores / idempotency keys).
3. Poison Pill & Dead Letter Queue (DLQ) Pattern:
   - Poison Pill: A corrupted message that consistently panics or errors out the consumer.
   - Without DLQ: Consumer crashes, message redelivered, crashes again (infinite poison loop!).
   - With DLQ: After N failed retries, route to Dead Letter Queue for alerting/debugging and advance offset.
4. Backpressure & Bounded Buffers:
   - Prevents Out-Of-Memory (OOM) when producers outpace consumers.
================================================================================
*/

type Message struct {
	ID        string
	Payload   string
	Attempts  int
	MaxRetry  int
	IsPoison  bool
	CreatedAt time.Time
}

type MessageQueue struct {
	mainQueue chan Message
	dlq       chan Message // Dead Letter Queue
	processed atomic.Uint64
	poisonDLQ atomic.Uint64
	wg        sync.WaitGroup
	closed    atomic.Bool
}

func NewMessageQueue(bufferSize int) *MessageQueue {
	return &MessageQueue{
		mainQueue: make(chan Message, bufferSize),
		dlq:       make(chan Message, bufferSize),
	}
}

// Publish enqueues a message with bounded buffer backpressure
func (mq *MessageQueue) Publish(msg Message) bool {
	if mq.closed.Load() {
		return false
	}
	mq.mainQueue <- msg
	return true
}

// StartWorkerPool launches N concurrent consumer workers
func (mq *MessageQueue) StartWorkerPool(numWorkers int) {
	for i := 1; i <= numWorkers; i++ {
		mq.wg.Add(1)
		go mq.worker(i)
	}
}

func (mq *MessageQueue) worker(workerID int) {
	defer mq.wg.Done()

	for msg := range mq.mainQueue {
		// Process message
		err := mq.processMessage(workerID, &msg)
		if err != nil {
			msg.Attempts++
			if msg.Attempts >= msg.MaxRetry {
				// Poison pill threshold reached -> Route to DLQ!
				mq.poisonDLQ.Add(1)
				fmt.Printf("  [WORKER-%d] Message %s exceeded %d retries! Routed to DEAD LETTER QUEUE (DLQ)\n",
					workerID, msg.ID, msg.MaxRetry)
				mq.dlq <- msg
			} else {
				// Re-queue with exponential backoff
				fmt.Printf("  [WORKER-%d] Message %s failed (Attempt %d/%d). Re-queueing...\n",
					workerID, msg.ID, msg.Attempts, msg.MaxRetry)
				time.Sleep(10 * time.Millisecond)
				mq.mainQueue <- msg
			}
			continue
		}

		mq.processed.Add(1)
	}
}

func (mq *MessageQueue) processMessage(workerID int, msg *Message) error {
	time.Sleep(15 * time.Millisecond) // Simulated compute workload

	if msg.IsPoison {
		return fmt.Errorf("fatal error: corrupt payload / unparseable schema")
	}

	fmt.Printf("  [WORKER-%d] Successfully processed: %s (%s)\n", workerID, msg.ID, msg.Payload)
	return nil
}

func (mq *MessageQueue) Shutdown() {
	mq.closed.Store(true)
	close(mq.mainQueue)
	mq.wg.Wait()
	close(mq.dlq)
}

func main() {
	fmt.Println("=== SD3 Message Queue: Competing Consumers, Backpressure & Dead Letter Queue (DLQ) ===")

	mq := NewMessageQueue(20)

	// Launch 3 competing consumers
	mq.StartWorkerPool(3)

	// 1. Publish Normal Valid Messages
	fmt.Println("\n[1] Publishing Normal Messages across 3 competing worker consumers:")
	mq.Publish(Message{ID: "msg-001", Payload: "Process order #101", MaxRetry: 3})
	mq.Publish(Message{ID: "msg-002", Payload: "Send welcome email", MaxRetry: 3})
	mq.Publish(Message{ID: "msg-003", Payload: "Generate PDF invoice", MaxRetry: 3})

	// 2. Publish Poison Pill Message (Simulates malformed corrupt payload)
	fmt.Println("\n[2] Publishing POISON PILL Message (Corrupted schema):")
	mq.Publish(Message{
		ID:       "msg-POISON-999",
		Payload:  "MALFORMED_DATA_NULL_BYTE",
		MaxRetry: 3,
		IsPoison: true,
	})

	time.Sleep(200 * time.Millisecond)
	mq.Shutdown()

	fmt.Printf("\n[3] Final Queue Processing Metrics:\n")
	fmt.Printf("  Successfully Processed: %d\n", mq.processed.Load())
	fmt.Printf("  Dead Letter Queue (DLQ) Messages: %d\n", mq.poisonDLQ.Load())

	// Inspect Dead Letter Queue
	for dlqMsg := range mq.dlq {
		fmt.Printf("  -> DLQ Inspector: Inspecting isolated poison message: [%s] '%s' (Failed attempts: %d)\n",
			dlqMsg.ID, dlqMsg.Payload, dlqMsg.Attempts)
	}

	fmt.Println("\n[SD3 Takeaway]: Dead Letter Queues prevent unprocessable poison pill messages from triggering catastrophic infinite retry loops in worker fleets.")
}
