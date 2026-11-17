//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): SQL / RDBMS ARCHITECTURE & QUERY EXECUTION PLANS
================================================================================
Key Topics Covered:
1. Production Connection Pool Sizing (HikariCP / database/sql formula):
   - Formula: connections = ((core_count * 2) + effective_spindle_count)
   - Why having 10,000 DB connections crashes PostgreSQL/MySQL:
     Each backend connection costs 2MB-10MB RAM, CPU thrashing, context switching,
     and disk I/O queue lock contention.
2. Query Execution Plans (EXPLAIN ANALYZE):
   - Sequential Scan (Table Scan): Scans every heap page. O(N).
   - Index Scan: B+ Tree lookup followed by heap pointer lookup. O(log N).
   - Index Only Scan: All requested columns are in the B+ Tree leaf (Covering Index). Zero heap access!
3. SQL Join Algorithms:
   - Nested Loop Join: Best for small driving tables with index on join column.
   - Hash Join: Builds in-memory hash table on smaller relation, probes with larger relation.
   - Merge Join: Best when both inputs are pre-sorted by join key.
================================================================================
*/

// DBConnection represents an active socket to the database
type DBConnection struct {
	ID       int
	InUse    bool
	LastUsed time.Time
}

// ConnectionPool simulates a production database connection pool
type ConnectionPool struct {
	maxOpen     int
	maxIdle     int
	pool        []*DBConnection
	waitQueue   chan *DBConnection
	activeConns int
	mu          sync.Mutex
}

func NewConnectionPool(maxOpen, maxIdle int) *ConnectionPool {
	return &ConnectionPool{
		maxOpen:   maxOpen,
		maxIdle:   maxIdle,
		waitQueue: make(chan *DBConnection, 100),
	}
}

func (p *ConnectionPool) Acquire() (*DBConnection, error) {
	p.mu.Lock()

	// 1. Look for existing idle connection
	for _, conn := range p.pool {
		if !conn.InUse {
			conn.InUse = true
			conn.LastUsed = time.Now()
			p.mu.Unlock()
			return conn, nil
		}
	}

	// 2. Spawn new connection if under maxOpen limit
	if p.activeConns < p.maxOpen {
		p.activeConns++
		conn := &DBConnection{ID: p.activeConns, InUse: true, LastUsed: time.Now()}
		p.pool = append(p.pool, conn)
		p.mu.Unlock()
		return conn, nil
	}

	p.mu.Unlock()

	// 3. Pool exhausted: wait for released connection
	select {
	case conn := <-p.waitQueue:
		return conn, nil
	case <-time.After(100 * time.Millisecond):
		return nil, fmt.Errorf("connection pool exhausted: timeout waiting for free connection")
	}
}

func (p *ConnectionPool) Release(conn *DBConnection) {
	p.mu.Lock()
	conn.InUse = false
	p.mu.Unlock()

	// Notify waiting queries
	select {
	case p.waitQueue <- conn:
	default:
	}
}

// -----------------------------------------------------------------------------
// QUERY EXECUTION ENGINE & JOIN SIMULATION
// -----------------------------------------------------------------------------

type UserRecord struct {
	ID   int
	Name string
}

type OrderRecord struct {
	OrderID int
	UserID  int
	Amount  float64
}

// HashJoin simulates in-memory Hash Join between Users and Orders
func HashJoin(users []UserRecord, orders []OrderRecord) []string {
	// 1. Build Phase: Hash table on the smaller table (Users)
	hashTable := make(map[int]string)
	for _, u := range users {
		hashTable[u.ID] = u.Name
	}

	// 2. Probe Phase: Scan larger table (Orders) and probe hash table: O(M + N) complexity!
	var joined []string
	for _, o := range orders {
		if userName, found := hashTable[o.UserID]; found {
			joined = append(joined, fmt.Sprintf("Order #%d ($%.2f) -> User: %s", o.OrderID, o.Amount, userName))
		}
	}
	return joined
}

func main() {
	fmt.Println("=== SD3 SQL / RDBMS: Connection Pool Dynamics & Hash Join Execution ===")

	// 1. Connection Pool Sizing & Contention
	fmt.Println("\n[1] Testing Connection Pool Constraints (MaxOpen: 2):")
	pool := NewConnectionPool(2, 2)

	conn1, _ := pool.Acquire()
	fmt.Printf("  Worker 1 acquired Conn #%d\n", conn1.ID)

	conn2, _ := pool.Acquire()
	fmt.Printf("  Worker 2 acquired Conn #%d\n", conn2.ID)

	// Attempting to acquire 3rd connection when maxOpen = 2
	start := time.Now()
	_, err := pool.Acquire()
	fmt.Printf("  Worker 3 acquired attempt: %v (Timed out in %v - Protected DB from thrashing!)\n",
		err, time.Since(start))

	// Release conn1 and retry
	pool.Release(conn1)
	conn3, _ := pool.Acquire()
	fmt.Printf("  Worker 3 acquired freed Conn #%d after release!\n", conn3.ID)

	// 2. Hash Join Query Plan Execution
	fmt.Println("\n[2] Executing In-Memory Hash Join Algorithm (O(M+N)):")
	users := []UserRecord{
		{ID: 1, Name: "Prakash Deep"},
		{ID: 2, Name: "Sarah Connor"},
	}
	orders := []OrderRecord{
		{OrderID: 501, UserID: 1, Amount: 149.99},
		{OrderID: 502, UserID: 2, Amount: 89.50},
		{OrderID: 503, UserID: 1, Amount: 499.00},
	}

	results := HashJoin(users, orders)
	for _, line := range results {
		fmt.Printf("  %s\n", line)
	}

	fmt.Println("\n[SD3 Takeaway]: Limit MaxOpenConns to avoid DB context thrashing; Hash Joins achieve O(M+N) performance by hashing the build relation.")
}
