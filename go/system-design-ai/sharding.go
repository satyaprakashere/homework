//go:build ignore

package main

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"sort"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DATABASE HORIZONTAL SHARDING & SCATTER-GATHER
================================================================================
Key Topics Covered:
1. Sharding Strategies & Trade-offs:
   - Hash-Based Sharding: Uniform key distribution, but difficult to reshard without consistent hashing.
   - Range-Based Sharding: Efficient range scans, but suffers Hotspotting on monotonically increasing IDs/dates.
   - Directory-Based Sharding: Lookup table maps ShardKey -> Shard. Highly flexible, requires caching.
2. Single-Shard Routing vs Cross-Shard Scatter-Gather:
   - Single-shard query (with Shard Key): Direct O(1) hop to exact target database instance.
   - Cross-shard query (without Shard Key): Scatter-Gather! Query dispatched to ALL N shards in parallel,
     results merged, paginated, and sorted in memory. Tail latency is bounded by the slowest shard!
3. Shard Key Selection Criteria:
   - High cardinality (e.g. user_id vs status).
   - Uniform query distribution (avoiding "Justin Bieber" celebrity hotspot shard).
================================================================================
*/

type Order struct {
	ID        int
	UserID    string // Shard Key
	Amount    float64
	CreatedAt time.Time
}

// ShardDatabase simulates a physical database instance
type ShardDatabase struct {
	ShardID int
	orders  []Order
	mu      sync.RWMutex
}

func (s *ShardDatabase) Insert(order Order) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.orders = append(s.orders, order)
}

func (s *ShardDatabase) QueryByUserID(userID string) []Order {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var res []Order
	for _, o := range s.orders {
		if o.UserID == userID {
			res = append(res, o)
		}
	}
	return res
}

func (s *ShardDatabase) QueryMinAmount(minAmount float64) []Order {
	s.mu.RLock()
	defer s.mu.RUnlock()
	time.Sleep(10 * time.Millisecond) // Simulated table scan latency
	var res []Order
	for _, o := range s.orders {
		if o.Amount >= minAmount {
			res = append(res, o)
		}
	}
	return res
}

// ShardedDatabaseCluster routes queries across multiple shards
type ShardedDatabaseCluster struct {
	shards []*ShardDatabase
}

func NewShardedCluster(numShards int) *ShardedDatabaseCluster {
	shards := make([]*ShardDatabase, numShards)
	for i := 0; i < numShards; i++ {
		shards[i] = &ShardDatabase{ShardID: i}
	}
	return &ShardedDatabaseCluster{shards: shards}
}

// getShardIndex calculates the target shard using Hash(UserID) % NumShards
func (c *ShardedDatabaseCluster) getShardIndex(userID string) int {
	h := sha256.Sum256([]byte(userID))
	val := binary.BigEndian.Uint32(h[:4])
	return int(val % uint32(len(c.shards)))
}

// RouteInsert inserts the record directly into the responsible shard
func (c *ShardedDatabaseCluster) RouteInsert(order Order) int {
	idx := c.getShardIndex(order.UserID)
	c.shards[idx].Insert(order)
	return idx
}

// QueryDirect executes an optimal O(1) single-shard query using the Shard Key
func (c *ShardedDatabaseCluster) QueryDirect(userID string) ([]Order, int) {
	idx := c.getShardIndex(userID)
	return c.shards[idx].QueryByUserID(userID), idx
}

// ScatterGather executes a cross-shard query across ALL shards concurrently
func (c *ShardedDatabaseCluster) ScatterGather(minAmount float64) []Order {
	var wg sync.WaitGroup
	resultsChan := make(chan []Order, len(c.shards))

	// SCATTER: Dispatch query to all shards in parallel
	for _, shard := range c.shards {
		wg.Add(1)
		go func(s *ShardDatabase) {
			defer wg.Done()
			resultsChan <- s.QueryMinAmount(minAmount)
		}(shard)
	}

	wg.Wait()
	close(resultsChan)

	// GATHER: Merge and sort results in memory
	var combined []Order
	for res := range resultsChan {
		combined = append(combined, res...)
	}

	// Sort by Amount descending
	sort.Slice(combined, func(i, j int) bool {
		return combined[i].Amount > combined[j].Amount
	})

	return combined
}

func main() {
	fmt.Println("=== SD3 Database Sharding: Direct Routing vs Scatter-Gather Queries ===")

	numShards := 4
	cluster := NewShardedCluster(numShards)

	// 1. Insert Orders distributed across 4 shards
	fmt.Printf("\n[1] Inserting Orders via Hash(UserID) mod %d:\n", numShards)
	sampleOrders := []Order{
		{ID: 101, UserID: "user_alpha", Amount: 250.00, CreatedAt: time.Now()},
		{ID: 102, UserID: "user_beta", Amount: 1400.00, CreatedAt: time.Now()},
		{ID: 103, UserID: "user_gamma", Amount: 50.00, CreatedAt: time.Now()},
		{ID: 104, UserID: "user_delta", Amount: 890.00, CreatedAt: time.Now()},
		{ID: 105, UserID: "user_alpha", Amount: 75.00, CreatedAt: time.Now()},
	}

	for _, o := range sampleOrders {
		shardID := cluster.RouteInsert(o)
		fmt.Printf("  Order #%d (%-11s, $%.2f) -> Routed to [Shard %d]\n", o.ID, o.UserID, o.Amount, shardID)
	}

	// 2. Optimal Query: Query WITH Shard Key (Single Shard Hit)
	fmt.Println("\n[2] Optimal Query WITH Shard Key (Single Shard Seek):")
	start := time.Now()
	orders, shardID := cluster.QueryDirect("user_alpha")
	fmt.Printf("  Query for 'user_alpha' targeted ONLY [Shard %d] in %v:\n", shardID, time.Since(start))
	for _, o := range orders {
		fmt.Printf("    -> Order #%d: $%.2f\n", o.ID, o.Amount)
	}

	// 3. Cross-Shard Query: Query WITHOUT Shard Key (Scatter-Gather)
	fmt.Println("\n[3] Cross-Shard Query WITHOUT Shard Key (Scatter-Gather Fanout):")
	fmt.Println("  Query: Find all orders >= $200 (Requires checking every shard!)")
	start = time.Now()
	highValueOrders := cluster.ScatterGather(200.00)
	fmt.Printf("  Scatter-Gather merged %d matching orders in %v:\n", len(highValueOrders), time.Since(start))
	for _, o := range highValueOrders {
		fmt.Printf("    -> Order #%d (%s): $%.2f\n", o.ID, o.UserID, o.Amount)
	}

	fmt.Println("\n[SD3 Takeaway]: Always pick high-cardinality shard keys that align with the most frequent query access patterns to avoid expensive Scatter-Gather fanouts.")
}
