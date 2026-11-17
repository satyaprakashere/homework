//go:build ignore

package main

import (
	"context"
	"fmt"
	"math/rand"
	"sync"
	"sync/atomic"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): TTL (TIME-TO-LIVE) EXPIRATION & MEMORY REAPING
================================================================================
Key Topics Covered:
1. Passive (Lazy) Expiration: Checks validity on read; purges expired entry on demand.
2. Active (Proactive) Expiration: Redis-style randomized sampling sweep to bound memory leaks.
3. TTL Jitter: Adding randomized variance to prevent synchronized massive cache stampedes.
4. Graceful Background Cleanup with cancellation context.

SD3 Architectural Insights:
- Memory Leak Risk with Pure Lazy Expiration:
  If an application sets 10M keys with 5-minute TTL, and 90% are never accessed again,
  lazy expiration will NEVER clean them up, leading to OOM (Out Of Memory)!
- Redis Active Sampling Algorithm:
  Redis samples 20 keys with TTL 10 times per second:
  - Purges all expired keys found.
  - If > 25% of sampled keys were expired, it repeats immediately (adaptive cycle).
  This bounds expired memory usage to < 25% on average with negligible CPU overhead.
- TTL Jitter Formula:
  TTL_effective = Base_TTL + UniformRandom(-Jitter, +Jitter)
  Prevents the "Black Friday 12:00:00 midnight" mass expiration cliff.
================================================================================
*/

type TTLEntry struct {
	value     any
	expiresAt time.Time
}

func (e *TTLEntry) IsExpired() bool {
	return time.Now().After(e.expiresAt)
}

// TTLCache is a production-grade in-memory cache with both passive and active expiration
type TTLCache struct {
	mu           sync.RWMutex
	store        map[string]*TTLEntry
	reapedCount  atomic.Uint64
	lazyEvictions atomic.Uint64
}

func NewTTLCache() *TTLCache {
	return &TTLCache{
		store: make(map[string]*TTLEntry),
	}
}

// Set adds an item with base TTL plus jitter to smooth expiration curves
func (c *TTLCache) Set(key string, val any, baseTTL time.Duration, jitterPercent float64) {
	c.mu.Lock()
	defer c.mu.Unlock()

	// Calculate jitter: e.g. 10s TTL with 10% jitter -> [9s, 11s]
	jitter := time.Duration(0)
	if jitterPercent > 0 {
		delta := float64(baseTTL) * jitterPercent
		randDelta := (rand.Float64()*2 - 1.0) * delta
		jitter = time.Duration(randDelta)
	}
	effectiveTTL := baseTTL + jitter

	c.store[key] = &TTLEntry{
		value:     val,
		expiresAt: time.Now().Add(effectiveTTL),
	}
}

// Get implements Passive / Lazy Expiration
func (c *TTLCache) Get(key string) (any, bool) {
	c.mu.RLock()
	entry, exists := c.store[key]
	c.mu.RUnlock()

	if !exists {
		return nil, false
	}

	// Check if expired
	if entry.IsExpired() {
		// Acquire write lock to lazily purge expired item
		c.mu.Lock()
		// Double check pattern under write lock
		if cur, ok := c.store[key]; ok && cur.IsExpired() {
			delete(c.store, key)
			c.lazyEvictions.Add(1)
		}
		c.mu.Unlock()
		return nil, false
	}

	return entry.value, true
}

// StartRedisStyleReaper periodically samples keys and deletes expired entries (Active Cleanup)
func (c *TTLCache) StartRedisStyleReaper(ctx context.Context, interval time.Duration, sampleSize int) {
	ticker := time.NewTicker(interval)
	go func() {
		for {
			select {
			case <-ctx.Done():
				ticker.Stop()
				return
			case <-ticker.C:
				c.sampleAndReap(sampleSize)
			}
		}
	}()
}

// sampleAndReap checks a random sample of keys to bound expired keys in memory
func (c *TTLCache) sampleAndReap(sampleSize int) {
	c.mu.Lock()
	defer c.mu.Unlock()

	if len(c.store) == 0 {
		return
	}

	expiredFound := 0
	inspected := 0
	now := time.Now()

	// Map iteration in Go provides randomized starting points
	for k, entry := range c.store {
		if inspected >= sampleSize {
			break
		}
		inspected++

		if now.After(entry.expiresAt) {
			delete(c.store, k)
			c.reapedCount.Add(1)
			expiredFound++
		}
	}

	// In Redis, if > 25% expired, loop continues, but in this demo sampleSize bounds the tick
}

func (c *TTLCache) Len() int {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return len(c.store)
}

func main() {
	fmt.Println("=== SD3 TTL & Active/Passive Cache Eviction Demo ===")

	cache := NewTTLCache()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start active reaper: samples 20 keys every 20ms
	cache.StartRedisStyleReaper(ctx, 20*time.Millisecond, 20)

	// 1. Test Lazy Expiration
	fmt.Println("\n[1] Testing Passive (Lazy) Expiration:")
	cache.Set("session:active", "UserData123", 500*time.Millisecond, 0)
	cache.Set("session:short", "TempToken", 50*time.Millisecond, 0)

	time.Sleep(70 * time.Millisecond)

	// session:short should be lazily evicted upon access
	if _, ok := cache.Get("session:short"); !ok {
		fmt.Printf("  session:short correctly expired lazily! (Lazy purges: %d)\n", cache.lazyEvictions.Load())
	}
	if val, ok := cache.Get("session:active"); ok {
		fmt.Printf("  session:active is still alive: %v\n", val)
	}

	// 2. Test Active Reaper (Zombie items never accessed again)
	fmt.Println("\n[2] Testing Active Sampling Reaper on Abandoned Keys (no Get() called):")
	for i := 0; i < 50; i++ {
		// Set short TTL of 40ms with 10% jitter
		cache.Set(fmt.Sprintf("abandoned:cart:%d", i), "item_data", 40*time.Millisecond, 0.1)
	}
	fmt.Printf("  Populated 50 abandoned cart keys. Cache Size: %d\n", cache.Len())

	// Wait for TTL to elapse + active reaper to sample and evict
	time.Sleep(120 * time.Millisecond)

	fmt.Printf("  After 120ms background reaping:\n")
	fmt.Printf("  Active Reaped count: %d\n", cache.reapedCount.Load())
	fmt.Printf("  Remaining items in cache: %d\n", cache.Len())

	fmt.Println("\n[SD3 Takeaway]: Active sweeping guarantees memory remains bounded even if keys are never accessed again.")
}
