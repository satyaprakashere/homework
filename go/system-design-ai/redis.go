//go:build ignore

package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"sort"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): REDIS ARCHITECTURE & DISTRIBUTED LOCKS
================================================================================
Key Topics Covered:
1. Redis Single-Threaded Event Loop Simulation.
2. Rich In-Memory Data Structures:
   - Strings (Key-Value)
   - Hashes (Field-Value sub-maps)
   - Sorted Sets (ZSET): Combines Hash (O(1) score lookup) + Skiplist (O(log N) ranking)
3. Safe Distributed Lock with TTL Lease and Atomic Lua Script Release:
   - SET lock_key unique_token NX PX 10000
   - Prevents the classic "GC Pause Lock Stealing Bug".
4. Persistence Tradeoffs (RDB Snapshots vs AOF Journaling).

SD3 Interview Gold:
- Question: "Why can't we just call DEL lock_key to release a distributed lock?"
  Answer:
  Suppose Worker 1 acquires lock with 5s lease. Worker 1 hits a Stop-The-World
  GC pause for 6s. The lock automatically expires.
  Worker 2 acquires the lock.
  Worker 1 wakes up and executes DEL lock_key.
  Worker 1 just deleted Worker 2's lock! Now Worker 3 also enters the critical section!
  Mutual exclusion is broken.
  SOLUTION: Must store a unique UUID in the lock and release ONLY via atomic Lua script:
  if redis.call("get", KEYS[1]) == ARGV[1] then
      return redis.call("del", KEYS[1])
  else
      return 0
  end
================================================================================
*/

// ZMember represents an element in a Redis Sorted Set (ZSET)
type ZMember struct {
	Member string
	Score  float64
}

// RedisServer simulates Redis single-threaded execution using a command channel
type RedisServer struct {
	cmdChan chan func()
	strings map[string]string
	ttls    map[string]time.Time
	hashes  map[string]map[string]string
	zsets   map[string]map[string]float64
}

func NewRedisServer() *RedisServer {
	srv := &RedisServer{
		cmdChan: make(chan func(), 10000),
		strings: make(map[string]string),
		ttls:    make(map[string]time.Time),
		hashes:  make(map[string]map[string]string),
		zsets:   make(map[string]map[string]float64),
	}
	// Start single-threaded event loop
	go func() {
		for cmd := range srv.cmdChan {
			cmd() // Execute synchronously: zero race conditions on internal state!
		}
	}()
	return srv
}

// execute runs a command synchronously on Redis's single thread
func (s *RedisServer) execute(fn func()) {
	done := make(chan struct{})
	s.cmdChan <- func() {
		fn()
		close(done)
	}
	<-done
}

// SetNX_PX simulates: SET key val NX PX milliseconds
func (s *RedisServer) SetNX_PX(key, val string, ttl time.Duration) bool {
	var acquired bool
	s.execute(func() {
		now := time.Now()
		if exp, exists := s.ttls[key]; exists && now.Before(exp) {
			acquired = false
			return
		}
		s.strings[key] = val
		s.ttls[key] = now.Add(ttl)
		acquired = true
	})
	return acquired
}

// EvalLuaUnlock executes the atomic Lua release script
func (s *RedisServer) EvalLuaUnlock(key, token string) bool {
	var released bool
	s.execute(func() {
		now := time.Now()
		exp, hasTTL := s.ttls[key]
		if hasTTL && now.After(exp) {
			released = false // Lock already expired
			return
		}

		if val, exists := s.strings[key]; exists && val == token {
			delete(s.strings, key)
			delete(s.ttls, key)
			released = true
		} else {
			released = false // Token mismatch! Belonged to another worker
		}
	})
	return released
}

// ZAdd adds a member with a score to a Sorted Set (ZSET)
func (s *RedisServer) ZAdd(key, member string, score float64) {
	s.execute(func() {
		if _, exists := s.zsets[key]; !exists {
			s.zsets[key] = make(map[string]float64)
		}
		s.zsets[key][member] = score
	})
}

// ZRevRangeWithScores returns top N members ordered by score descending
func (s *RedisServer) ZRevRangeWithScores(key string, limit int) []ZMember {
	var results []ZMember
	s.execute(func() {
		m, exists := s.zsets[key]
		if !exists {
			return
		}
		var list []ZMember
		for member, score := range m {
			list = append(list, ZMember{Member: member, Score: score})
		}
		// Sort by score descending
		sort.Slice(list, func(i, j int) bool {
			return list[i].Score > list[j].Score
		})
		if len(list) > limit {
			list = list[:limit]
		}
		results = list
	})
	return results
}

// -----------------------------------------------------------------------------
// DISTRIBUTED LOCK CLIENT
// -----------------------------------------------------------------------------

type DistributedLock struct {
	client *RedisServer
	key    string
	token  string
	ttl    time.Duration
}

func generateToken() string {
	b := make([]byte, 16)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func NewDistributedLock(client *RedisServer, key string, ttl time.Duration) *DistributedLock {
	return &DistributedLock{
		client: client,
		key:    key,
		token:  generateToken(),
		ttl:    ttl,
	}
}

func (l *DistributedLock) TryLock() bool {
	return l.client.SetNX_PX(l.key, l.token, l.ttl)
}

func (l *DistributedLock) Unlock() bool {
	return l.client.EvalLuaUnlock(l.key, l.token)
}

func main() {
	fmt.Println("=== SD3 Redis: Event-Loop, ZSET Leaderboard & Redlock Safe Unlocking ===")

	redis := NewRedisServer()

	// 1. ZSET Real-Time Leaderboard Demo (e.g. Gaming / Top K Trending)
	fmt.Println("\n[1] Testing Redis Sorted Set (ZSET) for Real-Time Leaderboards:")
	leaderboardKey := "leaderboard:weekly:global"
	redis.ZAdd(leaderboardKey, "player:alpha", 9820)
	redis.ZAdd(leaderboardKey, "player:beta", 15400)
	redis.ZAdd(leaderboardKey, "player:gamma", 12300)
	redis.ZAdd(leaderboardKey, "player:delta", 19500)

	top3 := redis.ZRevRangeWithScores(leaderboardKey, 3)
	fmt.Println("  Top 3 High Scores:")
	for rank, p := range top3 {
		fmt.Printf("    Rank #%d: %-15s Score: %.0f\n", rank+1, p.Member, p.Score)
	}

	// 2. Distributed Locking with Mutual Exclusion
	fmt.Println("\n[2] Testing Distributed Lock Mutual Exclusion (5 workers fighting for 1 lock):")
	resource := "lock:inventory:item:551"
	var wg sync.WaitGroup
	var lockHolder string
	var mu sync.Mutex

	for i := 1; i <= 5; i++ {
		wg.Add(1)
		go func(workerID int) {
			defer wg.Done()
			lock := NewDistributedLock(redis, resource, 100*time.Millisecond)
			if lock.TryLock() {
				mu.Lock()
				lockHolder = fmt.Sprintf("Worker-%d", workerID)
				fmt.Printf("  [SUCCESS] %s acquired the lock!\n", lockHolder)
				mu.Unlock()
				time.Sleep(20 * time.Millisecond) // critical section
				lock.Unlock()
			} else {
				fmt.Printf("  [REJECTED] Worker-%d could NOT acquire lock (busy).\n", workerID)
			}
		}(i)
	}
	wg.Wait()

	// 3. Simulating the "GC Pause Lock Stealing Bug" Prevention
	fmt.Println("\n[3] Testing Atomic Lua Unlock Guard Against Stolen Lock Expiration:")
	lockA := NewDistributedLock(redis, "lock:account:balance", 30*time.Millisecond)
	lockB := NewDistributedLock(redis, "lock:account:balance", 100*time.Millisecond)

	fmt.Println("  Worker A acquires lock with 30ms lease...")
	lockA.TryLock()

	// Simulate Worker A freezing (e.g. 50ms GC pause) -> Lock expires!
	time.Sleep(50 * time.Millisecond)
	fmt.Println("  30ms elapsed -> Worker A's lease expired automatically in Redis.")

	// Worker B acquires the newly freed lock
	acquired := lockB.TryLock()
	fmt.Printf("  Worker B acquires lock: %v\n", acquired)

	// Worker A wakes up from freeze and attempts to unlock:
	released := lockA.Unlock()
	fmt.Printf("  Worker A tries to unlock: %v (Safely BLOCKED by Lua script: Token mismatch!)\n", released)

	// Worker B safely finishes its own work
	fmt.Printf("  Worker B releases its own lock: %v\n", lockB.Unlock())

	fmt.Println("\n[SD3 Takeaway]: Redis single-threaded execution guarantees atomicity. Lua scripts with unique tokens protect distributed locks from split-brain state.")
}
