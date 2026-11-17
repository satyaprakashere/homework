//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): CACHE INVALIDATION & RACE CONDITIONS
================================================================================
Key Topics Covered:
1. The classic Cache-Aside Race Condition (Stale Data Overwrite).
2. Why DELETE cache on write is preferred over UPDATE cache.
3. Mitigation Pattern 1: Delayed Double Deletion (Cache-Aside standard).
4. Mitigation Pattern 2: Versioned / Generational Tokens (CAS - Check And Set).
5. Event-Driven Invalidation via CDC (Change Data Capture / WAL streaming).

SD3 Interview Gold:
- Question: "Why should we delete cache rather than updating cache when DB updates?"
  Answer:
  1) Concurrency Race: Two writes W1 and W2 happen. W1 updates DB first, W2 updates DB second.
     Due to network latency, W2's cache update reaches Redis first, and W1's reaches second.
     Now Cache has W1 (stale) while DB has W2 (fresh)!
     Deleting the cache avoids this entirely.
  2) Write Cost: If data is updated frequently but read infrequently, computing and updating
     the cache on every write is wasted CPU/bandwidth. Lazy deletion is much cheaper.

- Question: "Can Cache-Aside still suffer a race condition on delete?"
  Answer:
  Yes! Time sequence:
  1. Thread 1 (Read): Cache miss. Reads DB (Value = A).
  2. Thread 2 (Write): Updates DB (Value = B). Deletes Cache.
  3. Thread 1 (Read): Writes stale (Value = A) to Cache.
  Cache is now stale until TTL expiry.
  Solution: Delayed Double Deletion OR Versioned Token Check (Compare-And-Set).
================================================================================
*/

// Record represents a database entity
type Record struct {
	Value   string
	Version int64
}

// Database simulates an ACID database with row versions
type Database struct {
	mu   sync.RWMutex
	data map[string]Record
}

func NewDatabase() *Database {
	return &Database{data: make(map[string]Record)}
}

func (db *Database) Read(key string) (Record, bool) {
	db.mu.RLock()
	defer db.mu.RUnlock()
	time.Sleep(10 * time.Millisecond) // Simulated disk I/O
	rec, ok := db.data[key]
	return rec, ok
}

func (db *Database) Write(key string, val string) Record {
	db.mu.Lock()
	defer db.mu.Unlock()
	time.Sleep(10 * time.Millisecond) // Simulated WAL write

	rec := db.data[key]
	rec.Value = val
	rec.Version++
	db.data[key] = rec
	return rec
}

// DistributedCache simulates Redis/Memcached with CAS/Version support
type DistributedCache struct {
	mu    sync.RWMutex
	store map[string]Record
}

func NewDistributedCache() *DistributedCache {
	return &DistributedCache{store: make(map[string]Record)}
}

func (c *DistributedCache) Get(key string) (Record, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	rec, ok := c.store[key]
	return rec, ok
}

func (c *DistributedCache) Delete(key string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.store, key)
}

// SetIfNewer implements version-guarded cache population (CAS / Optimistic Invalidation)
// Prevents stale reads from overwriting newer writes!
func (c *DistributedCache) SetIfNewer(key string, rec Record) bool {
	c.mu.Lock()
	defer c.mu.Unlock()

	current, exists := c.store[key]
	if !exists || rec.Version >= current.Version {
		c.store[key] = rec
		return true
	}
	// Rejected because incoming record is older than what we already invalidated/know
	return false
}

// Service demonstrates the Delayed Double Deletion pattern
type InvalidationService struct {
	db    *Database
	cache *DistributedCache
}

// WriteWithDelayedDoubleDeletion performs safe cache invalidation
func (s *InvalidationService) WriteWithDelayedDoubleDeletion(key, newVal string) {
	// Step 1: Pre-delete cache
	s.cache.Delete(key)
	fmt.Printf("  [Write] Pre-deleted cache for key: %s\n", key)

	// Step 2: Write to persistent DB
	rec := s.db.Write(key, newVal)
	fmt.Printf("  [Write] Committed to DB: %s = %s (v%d)\n", key, rec.Value, rec.Version)

	// Step 3: Asynchronously trigger delayed second deletion
	// This ensures that any read operation that was in-flight during the DB write
	// and mistakenly repopulated the cache with stale data gets flushed!
	go func() {
		time.Sleep(50 * time.Millisecond) // sleep longer than max read duration
		s.cache.Delete(key)
		fmt.Printf("  [Delayed Double Delete] Executed second cache purge for key: %s\n", key)
	}()
}

// ReadWithVersionProtection safely reads data preventing stale overwrite
func (s *InvalidationService) ReadWithVersionProtection(key string) Record {
	// 1. Try cache
	if rec, hit := s.cache.Get(key); hit {
		return rec
	}

	// 2. Read DB on cache miss
	rec, _ := s.db.Read(key)

	// 3. Populate cache conditionally (reject if newer data was written in the interim)
	accepted := s.cache.SetIfNewer(key, rec)
	if !accepted {
		fmt.Printf("  [Read] Blocked stale cache population for %s (v%d)!\n", key, rec.Version)
	}
	return rec
}

func main() {
	fmt.Println("=== SD3 Cache Invalidation Patterns & Anti-Stale Protections ===")

	db := NewDatabase()
	cache := NewDistributedCache()
	svc := &InvalidationService{db: db, cache: cache}

	key := "user:profile:101"
	db.Write(key, "Alice_v1")

	// 1. Demonstrate Version Guarded Cache Update
	fmt.Println("\n[Scenario 1: Version-Guarded Read-Through]")
	r1 := svc.ReadWithVersionProtection(key)
	fmt.Printf("  Read result: %+v\n", r1)

	// 2. Demonstrate Delayed Double Deletion
	fmt.Println("\n[Scenario 2: Delayed Double Deletion on Concurrent Write]")
	svc.WriteWithDelayedDoubleDeletion(key, "Alice_v2")

	// Sleep briefly to let the delayed deletion complete
	time.Sleep(100 * time.Millisecond)

	// Read again -> will fetch v2 from DB and populate cache
	r2 := svc.ReadWithVersionProtection(key)
	fmt.Printf("  Post-invalidation Read result: %+v\n", r2)

	fmt.Println("\n[SD3 Takeaway]: Invalidation avoids write-write races; Delayed Double Deletion + CAS versions eliminate read-write races.")
}
