//go:build ignore

package main

import (
	"container/list"
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): CACHING DEEP DIVE
================================================================================
Key Topics Covered:
1. Thread-Safe O(1) LRU (Least Recently Used) Cache implementation.
2. Cache-Aside (Lazy Loading) pattern.
3. Thundering Herd / Cache Stampede mitigation via Singleflight (Request Coalescing).
4. Cache Metrics: Hit ratio, eviction count, latency comparison.

SD3 Trade-offs to discuss in interviews:
- Eviction Policies: LRU vs LFU vs ARC vs FIFO vs Random.
- Caching Strategies:
    * Cache-Aside: App coordinates cache and DB. Eventual consistency. High availability.
    * Read-Through / Write-Through: App talks only to Cache. Cache handles DB. Consistent, higher write latency.
    * Write-Back (Write-Behind): Write to cache first, async batch write to DB. Risk of data loss on crash!
    * Write-Around: Write directly to DB; cache populated only on subsequent read. Good for write-heavy, rarely-read data.
- Thundering Herd Problem:
    When a popular key expires (or on cold start), 10,000 concurrent requests all miss cache
    and hit the database simultaneously, causing database crash.
    Solution: Singleflight / Mutex locking per key / Probabilistic Early Expiration (XFetch).
================================================================================
*/

// lruEntry represents a key-value node in the doubly linked list
type lruEntry struct {
	key   string
	value any
}

// LRUCache is a high-performance, thread-safe LRU Cache
type LRUCache struct {
	capacity  int
	mu        sync.RWMutex
	items     map[string]*list.Element
	evictList *list.List

	// Observability Metrics
	hits      atomic.Uint64
	misses    atomic.Uint64
	evictions atomic.Uint64
}

// NewLRUCache initializes an LRU cache with the specified capacity
func NewLRUCache(capacity int) *LRUCache {
	return &LRUCache{
		capacity:  capacity,
		items:     make(map[string]*list.Element),
		evictList: list.New(),
	}
}

// Get retrieves a key from the cache and marks it as recently used
func (c *LRUCache) Get(key string) (any, bool) {
	c.mu.Lock() // Write lock needed because moving element to front mutates list pointers
	defer c.mu.Unlock()

	if elem, found := c.items[key]; found {
		c.evictList.MoveToFront(elem)
		c.hits.Add(1)
		return elem.Value.(*lruEntry).value, true
	}

	c.misses.Add(1)
	return nil, false
}

// Put adds or updates a key in the cache. Evicts LRU item if capacity is exceeded.
func (c *LRUCache) Put(key string, value any) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// 1. Update existing key
	if elem, found := c.items[key]; found {
		c.evictList.MoveToFront(elem)
		elem.Value.(*lruEntry).value = value
		return
	}

	// 2. Check capacity and evict least recently used (at back of list)
	if c.evictList.Len() >= c.capacity {
		back := c.evictList.Back()
		if back != nil {
			c.evictList.Remove(back)
			kv := back.Value.(*lruEntry)
			delete(c.items, kv.key)
			c.evictions.Add(1)
		}
	}

	// 3. Insert new element at front
	elem := c.evictList.PushFront(&lruEntry{key: key, value: value})
	c.items[key] = elem
}

// Stats returns hit ratio and operational statistics
func (c *LRUCache) Stats() (hits, misses, evictions uint64, hitRatio float64) {
	hits = c.hits.Load()
	misses = c.misses.Load()
	evictions = c.evictions.Load()
	total := hits + misses
	if total > 0 {
		hitRatio = float64(hits) / float64(total) * 100.0
	}
	return
}

// -----------------------------------------------------------------------------
// SINGLEFLIGHT PATTERN: THUNDERING HERD / CACHE STAMPEDE MITIGATION
// -----------------------------------------------------------------------------

type call struct {
	wg  sync.WaitGroup
	val any
	err error
}

// SingleFlight suppresses duplicate concurrent function calls for the same key
type SingleFlight struct {
	mu sync.Mutex
	m  map[string]*call
}

func NewSingleFlight() *SingleFlight {
	return &SingleFlight{m: make(map[string]*call)}
}

// Do executes and returns the result of the given function, making sure that
// only one execution is in-flight for a given key at a time.
func (g *SingleFlight) Do(key string, fn func() (any, error)) (any, error) {
	g.mu.Lock()
	if c, ok := g.m[key]; ok {
		// Another goroutine is already fetching this key. Wait for it!
		g.mu.Unlock()
		c.wg.Wait()
		return c.val, c.err
	}

	c := new(call)
	c.wg.Add(1)
	g.m[key] = c
	g.mu.Unlock()

	// Execute the fetch function (e.g. database query)
	c.val, c.err = fn()
	c.wg.Done()

	g.mu.Lock()
	delete(g.m, key)
	g.mu.Unlock()

	return c.val, c.err
}

// -----------------------------------------------------------------------------
// SIMULATED DATABASE & CACHE SERVICE
// -----------------------------------------------------------------------------

type MockDatabase struct {
	queryCount atomic.Uint64
}

func (db *MockDatabase) QueryProduct(id string) string {
	// Simulate expensive I/O latency: 50ms database query
	db.queryCount.Add(1)
	time.Sleep(50 * time.Millisecond)
	return fmt.Sprintf(`{"id": "%s", "name": "High Performance Server", "price": 4999}`, id)
}

func main() {
	fmt.Println("=== SD3 Caching: LRU & Thundering Herd (Singleflight) Demo ===")

	cache := NewLRUCache(3) // small capacity to demonstrate eviction
	db := &MockDatabase{}
	sf := NewSingleFlight()

	// 1. Basic LRU Eviction Demo
	fmt.Println("\n[1] Testing LRU Eviction (Capacity: 3):")
	cache.Put("item:1", "Data 1")
	cache.Put("item:2", "Data 2")
	cache.Put("item:3", "Data 3")
	fmt.Println("  Loaded item:1, item:2, item:3")

	// Access item:1 to make item:2 the least recently used
	cache.Get("item:1")
	fmt.Println("  Accessed item:1 (now most recent).")

	// Put item:4 -> should evict item:2!
	cache.Put("item:4", "Data 4")
	fmt.Println("  Added item:4. Capacity exceeded, evicting LRU element...")

	if _, found := cache.Get("item:2"); !found {
		fmt.Println("  -> Confirmed: item:2 was correctly evicted!")
	}
	if _, found := cache.Get("item:1"); found {
		fmt.Println("  -> Confirmed: item:1 is still retained!")
	}

	// 2. Thundering Herd (Cache Stampede) Simulation
	fmt.Println("\n[2] Simulating Cache Stampede (50 concurrent requests for an uncached key):")
	key := "product:9999"

	var wg sync.WaitGroup
	start := time.Now()
	concurrency := 50

	for i := 0; i < concurrency; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()

			// Cache-Aside with Singleflight Coalescing:
			val, hit := cache.Get(key)
			if !hit {
				// Coalesce duplicate in-flight DB queries
				data, err := sf.Do(key, func() (any, error) {
					// Only ONE goroutine will enter this block!
					result := db.QueryProduct(key)
					cache.Put(key, result)
					return result, nil
				})
				if err != nil {
					return
				}
				val = data
			}
			_ = val
		}(i)
	}

	wg.Wait()
	elapsed := time.Since(start)

	hits, misses, evictions, hitRatio := cache.Stats()
	fmt.Printf("  Total concurrent requests : %d\n", concurrency)
	fmt.Printf("  Actual DB queries made    : %d (WITHOUT Singleflight this would be %d!)\n", db.queryCount.Load(), concurrency)
	fmt.Printf("  Time elapsed              : %v\n", elapsed)
	fmt.Printf("  Cache Hits: %d | Misses: %d | Evictions: %d | Hit Ratio: %.2f%%\n", hits, misses, evictions, hitRatio)

	fmt.Println("\n[SD3 Takeaway]: Singleflight collapsed 50 parallel DB hits into exactly 1 database query!")
}
