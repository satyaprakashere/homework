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
SYSTEM DESIGN INTERVIEW (SD3): GRAPHQL ARCHITECTURE & THE N+1 PROBLEM (DATALOADER)
================================================================================
Key Topics Covered:
1. GraphQL vs REST Trade-offs:
   - Over-fetching: REST /users/1 returns 40 fields; GraphQL returns only { id, email }.
   - Under-fetching: REST requires multiple round trips (/users/1 then /users/1/orders);
     GraphQL resolves nested graph relationships in 1 round trip.
2. The N+1 Query Problem:
   - Fetching 20 Posts and their Authors causes 1 query for posts + 20 individual queries for authors!
   - 1 + 20 = 21 database round trips.
3. DataLoader Pattern (Facebook):
   - Request-scoped Batching & Caching.
   - Collects all author IDs requested across the entire AST execution tick.
   - Replaces N individual SELECTs with exactly ONE: SELECT * FROM users WHERE id IN (...).
================================================================================
*/

type User struct {
	ID   int
	Name string
}

type Post struct {
	ID       int
	Title    string
	AuthorID int
}

// MockDatabase tracks total SQL queries executed
type MockDatabase struct {
	queriesCount atomic.Uint64
}

func (db *MockDatabase) QueryPosts() []Post {
	db.queriesCount.Add(1)
	return []Post{
		{ID: 1, Title: "Microservices in Go", AuthorID: 101},
		{ID: 2, Title: "Distributed Consensus", AuthorID: 102},
		{ID: 3, Title: "Consistent Hashing Deep Dive", AuthorID: 101}, // shares author 101
		{ID: 4, Title: "LSM Trees vs B+ Trees", AuthorID: 103},
		{ID: 5, Title: "Designing Idempotency", AuthorID: 102},       // shares author 102
	}
}

// Naive individual fetch: Triggers N+1 problem!
func (db *MockDatabase) QueryUserByID(id int) User {
	db.queriesCount.Add(1)
	time.Sleep(5 * time.Millisecond) // Simulated DB latency
	return User{ID: id, Name: fmt.Sprintf("Author_%d", id)}
}

// Batch fetch: DataLoader uses this to fetch in 1 query!
func (db *MockDatabase) QueryUsersByBatchIDs(ids []int) map[int]User {
	db.queriesCount.Add(1)
	time.Sleep(5 * time.Millisecond) // Simulated single batch DB query
	results := make(map[int]User)
	for _, id := range ids {
		results[id] = User{ID: id, Name: fmt.Sprintf("Author_%d", id)}
	}
	return results
}

// -----------------------------------------------------------------------------
// DATALOADER IMPLEMENTATION (BATCHING + PER-REQUEST CACHING)
// -----------------------------------------------------------------------------

type UserDataLoader struct {
	db       *MockDatabase
	cache    map[int]User
	pending  []int
	callbacks map[int][]chan User
	mu       sync.Mutex
}

func NewUserDataLoader(db *MockDatabase) *UserDataLoader {
	return &UserDataLoader{
		db:        db,
		cache:     make(map[int]User),
		callbacks: make(map[int][]chan User),
	}
}

func (l *UserDataLoader) Load(authorID int) <-chan User {
	l.mu.Lock()
	defer l.mu.Unlock()

	ch := make(chan User, 1)

	// 1. Check per-request cache
	if user, hit := l.cache[authorID]; hit {
		ch <- user
		return ch
	}

	// 2. Queue for batching
	l.callbacks[authorID] = append(l.callbacks[authorID], ch)
	l.pending = append(l.pending, authorID)

	return ch
}

// Dispatch executes the accumulated batch query in a single DB round trip
func (l *UserDataLoader) Dispatch() {
	l.mu.Lock()
	if len(l.pending) == 0 {
		l.mu.Unlock()
		return
	}

	// Deduplicate pending IDs
	uniqueMap := make(map[int]bool)
	var batchIDs []int
	for _, id := range l.pending {
		if !uniqueMap[id] {
			uniqueMap[id] = true
			batchIDs = append(batchIDs, id)
		}
	}
	l.pending = nil
	pendingCallbacks := l.callbacks
	l.callbacks = make(map[int][]chan User)
	l.mu.Unlock()

	// Execute 1 single batch SQL query: SELECT * FROM users WHERE id IN (...)
	batchResults := l.db.QueryUsersByBatchIDs(batchIDs)

	l.mu.Lock()
	for id, user := range batchResults {
		l.cache[id] = user
		for _, ch := range pendingCallbacks[id] {
			ch <- user
		}
	}
	l.mu.Unlock()
}

func main() {
	fmt.Println("=== SD3 GraphQL: AST Resolution & DataLoader Solving N+1 Problem ===")

	// 1. Naive Execution (N+1 Query Disaster)
	dbNaive := &MockDatabase{}
	posts := dbNaive.QueryPosts()

	fmt.Println("\n[1] Naive GraphQL Field Resolvers (WITHOUT DataLoader):")
	start := time.Now()
	for _, post := range posts {
		author := dbNaive.QueryUserByID(post.AuthorID)
		_ = author
	}
	fmt.Printf("  Fetched %d posts.\n", len(posts))
	fmt.Printf("  Total DB queries made: %d (1 post query + %d author queries = N+1 problem!)\n",
		dbNaive.queriesCount.Load(), len(posts))
	fmt.Printf("  Time elapsed: %v\n", time.Since(start))

	// 2. Optimized Execution with DataLoader (Batching + Caching)
	dbOptimized := &MockDatabase{}
	postsOpt := dbOptimized.QueryPosts()
	loader := NewUserDataLoader(dbOptimized)

	fmt.Println("\n[2] Optimized GraphQL Resolvers with DataLoader Pattern:")
	start = time.Now()

	// Field resolvers enqueue requests into loader
	var channels []<-chan User
	for _, post := range postsOpt {
		ch := loader.Load(post.AuthorID)
		channels = append(channels, ch)
	}

	// DataLoader dispatches 1 batched query for all unique authors!
	loader.Dispatch()

	// Collect resolved author data
	for i, ch := range channels {
		author := <-ch
		fmt.Printf("  Post #%d ('%s') -> Author: %s\n", postsOpt[i].ID, postsOpt[i].Title, author.Name)
	}

	fmt.Printf("  Total DB queries made: %d (1 post query + exactly 1 batched author query!)\n",
		dbOptimized.queriesCount.Load())
	fmt.Printf("  Time elapsed: %v\n", time.Since(start))

	fmt.Println("\n[SD3 Takeaway]: In GraphQL, DataLoader collapses N field resolver calls into 1 batched DB query with request-scoped caching.")
}
