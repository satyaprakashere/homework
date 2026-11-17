//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): NOSQL ARCHITECTURES, CAP/PACELC & QUORUMS
================================================================================
Key Topics Covered:
1. NoSQL Storage Models:
   - Key-Value (DynamoDB, Redis): High throughput, simple O(1) point lookups.
   - Document (MongoDB): Rich polymorphic schemas, embedded documents.
   - Wide-Column (Cassandra): Partition Key (sharding) + Clustering Column (sorting).
   - Graph (Neo4j): Index-Free Adjacency for O(1) relationship pointer chasing.
2. The PACELC Theorem:
   - If Partitioned (P): Tradeoff between Availability (A) and Consistency (C).
   - Else (E): Tradeoff between Latency (L) and Consistency (C).
3. Dynamo-Style Tunable Quorum Math:
   - N = Replication Factor (e.g. 3 replicas).
   - W = Write Quorum (minimum ACKs required before confirming write to client).
   - R = Read Quorum (minimum replicas queried on read).
   - Strict Consistency Condition: W + R > N (Pigeonhole Principle guarantees overlap).
   - High-Availability Write Condition: W = 1, R = 3 (Ultra fast writes, slower reads).
================================================================================
*/

type NodeRecord struct {
	Value     string
	Timestamp int64 // Lamport / Physical timestamp for Last-Write-Wins (LWW)
}

// ReplicaNode simulates one Cassandra / Dynamo node
type ReplicaNode struct {
	ID    int
	data  map[string]NodeRecord
	mu    sync.RWMutex
	delay time.Duration
}

func (n *ReplicaNode) Write(key, val string, ts int64) bool {
	n.mu.Lock()
	defer n.mu.Unlock()
	time.Sleep(n.delay) // Simulated network latency

	current, exists := n.data[key]
	if !exists || ts > current.Timestamp {
		n.data[key] = NodeRecord{Value: val, Timestamp: ts}
		return true
	}
	return false // Older timestamp rejected by LWW
}

func (n *ReplicaNode) Read(key string) (NodeRecord, bool) {
	n.mu.RLock()
	defer n.mu.RUnlock()
	time.Sleep(n.delay)
	rec, ok := n.data[key]
	return rec, ok
}

// DistributedCluster coordinates tunable quorum reads and writes
type DistributedCluster struct {
	nodes []*ReplicaNode
	N     int // Total replicas
}

func NewCluster(delays []time.Duration) *DistributedCluster {
	nodes := make([]*ReplicaNode, len(delays))
	for i, d := range delays {
		nodes[i] = &ReplicaNode{
			ID:    i + 1,
			data:  make(map[string]NodeRecord),
			delay: d,
		}
	}
	return &DistributedCluster{nodes: nodes, N: len(nodes)}
}

// QuorumWrite writes to all nodes concurrently and waits for W ACKs
func (c *DistributedCluster) QuorumWrite(key, val string, W int) (bool, time.Duration) {
	start := time.Now()
	ts := time.Now().UnixNano()

	ackChan := make(chan bool, c.N)
	for _, node := range c.nodes {
		go func(n *ReplicaNode) {
			ackChan <- n.Write(key, val, ts)
		}(node)
	}

	acks := 0
	for i := 0; i < c.N; i++ {
		if <-ackChan {
			acks++
			if acks >= W {
				// Met quorum threshold! Return success without waiting for remaining nodes
				return true, time.Since(start)
			}
		}
	}
	return false, time.Since(start)
}

// QuorumRead queries replicas and reconciles using Last-Write-Wins (LWW)
func (c *DistributedCluster) QuorumRead(key string, R int) (string, time.Duration) {
	start := time.Now()

	type readResult struct {
		rec   NodeRecord
		found bool
	}
	resChan := make(chan readResult, c.N)

	for _, node := range c.nodes {
		go func(n *ReplicaNode) {
			rec, found := n.Read(key)
			resChan <- readResult{rec: rec, found: found}
		}(node)
	}

	var latest NodeRecord
	responses := 0

	for i := 0; i < c.N; i++ {
		res := <-resChan
		if res.found {
			responses++
			if res.rec.Timestamp > latest.Timestamp {
				latest = res.rec
			}
			if responses >= R {
				// Met read quorum threshold!
				return latest.Value, time.Since(start)
			}
		}
	}

	return latest.Value, time.Since(start)
}

func main() {
	fmt.Println("=== SD3 NoSQL: Dynamo-Style Tunable Quorums (W + R > N) & PACELC ===")

	// 3-node replica cluster with heterogeneous network latencies: Node 1 (fast), Node 2 (medium), Node 3 (slow/cross-region)
	cluster := NewCluster([]time.Duration{
		5 * time.Millisecond,
		15 * time.Millisecond,
		50 * time.Millisecond,
	})

	key := "user:session:tok_991"

	// Scenario 1: High Availability Write (W=1, R=3)
	// W=1 allows writing as fast as the single fastest node!
	fmt.Println("\n[1] Testing Fast Low-Latency Write (W = 1):")
	_, latencyW1 := cluster.QuorumWrite(key, "session_v1_fast", 1)
	fmt.Printf("  Write confirmed with W=1 in %v (Only waited for fastest replica!)\n", latencyW1)

	// Scenario 2: Strict Strong Consistency Quorum (N=3, W=2, R=2 -> W + R = 4 > 3)
	fmt.Println("\n[2] Testing Strict Strong Consistency Quorum (W=2, R=2):")
	_, latencyW2 := cluster.QuorumWrite(key, "session_v2_strong", 2)
	fmt.Printf("  Write confirmed with W=2 in %v (Waited for majority consensus)\n", latencyW2)

	valRead, latencyR2 := cluster.QuorumRead(key, 2)
	fmt.Printf("  Read confirmed with R=2 in %v. Value: '%s'\n", latencyR2, valRead)

	fmt.Printf("\n  Quorum Math Check: W(%d) + R(%d) = %d > N(%d) -> GUARANTEED STRONGLY CONSISTENT!\n",
		2, 2, 4, 3)

	fmt.Println("\n[SD3 Takeaway]: Cassandra & DynamoDB leverage W+R>N for tunable consistency, letting architects choose between latency and strict durability.")
}
