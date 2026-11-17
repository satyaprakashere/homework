//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): REPLICATION MODES & READ-YOUR-OWN-WRITES
================================================================================
Key Topics Covered:
1. Replication Modes & Trade-offs:
   - Synchronous: Strict consistency, zero failover data loss, but highest write latency (blocks on slow replica).
   - Asynchronous: Ultra-low write latency, but failover causes data loss of un-replicated WAL logs.
   - Semi-Synchronous: Leader confirms write as soon as ONE synchronous replica ACKs; remaining replicas replicate asynchronously.
2. Replication Lag Anomalies & Mitigations:
   - Read-Your-Own-Writes Anomaly: User submits comment (to Primary Leader). On reload, query hits Read Replica
     with 50ms lag -> comment is missing! User thinks site is broken and re-submits (duplicate submission).
   - Mitigation: Route reads for the user's OWN recently modified data to the Primary for 60 seconds;
     all other global reads hit Read Replicas.
================================================================================
*/

type DataRecord struct {
	Value     string
	Version   int
	UpdatedAt time.Time
}

// ReadReplica simulates an asynchronous read replica with network replication lag
type ReadReplica struct {
	ID    int
	data  map[string]DataRecord
	lag   time.Duration
	mu    sync.RWMutex
}

func NewReadReplica(id int, lag time.Duration) *ReadReplica {
	return &ReadReplica{
		ID:   id,
		data: make(map[string]DataRecord),
		lag:  lag,
	}
}

func (r *ReadReplica) ApplyReplicationStream(key string, rec DataRecord) {
	// Replicate in background after replication lag
	go func() {
		time.Sleep(r.lag)
		r.mu.Lock()
		r.data[key] = rec
		r.mu.Unlock()
	}()
}

func (r *ReadReplica) Read(key string) (DataRecord, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	rec, ok := r.data[key]
	return rec, ok
}

// PrimaryLeader handles writes and orchestrates replication
type PrimaryLeader struct {
	data     map[string]DataRecord
	replicas []*ReadReplica
	mu       sync.RWMutex
}

func NewPrimaryLeader(replicas []*ReadReplica) *PrimaryLeader {
	return &PrimaryLeader{
		data:     make(map[string]DataRecord),
		replicas: replicas,
	}
}

// WriteAsync commits locally and replicates asynchronously in the background
func (l *PrimaryLeader) WriteAsync(key, val string) DataRecord {
	l.mu.Lock()
	defer l.mu.Unlock()

	rec := l.data[key]
	rec.Value = val
	rec.Version++
	rec.UpdatedAt = time.Now()
	l.data[key] = rec

	// Dispatch async replication stream to all read replicas
	for _, rep := range l.replicas {
		rep.ApplyReplicationStream(key, rec)
	}

	return rec
}

func (l *PrimaryLeader) Read(key string) (DataRecord, bool) {
	l.mu.RLock()
	defer l.mu.RUnlock()
	rec, ok := l.data[key]
	return rec, ok
}

// GatewayRouter enforces Read-Your-Own-Writes consistency
type GatewayRouter struct {
	leader       *PrimaryLeader
	replicas     []*ReadReplica
	userLastEdit map[string]time.Time // UserID -> LastWriteTime
	mu           sync.RWMutex
}

func NewGatewayRouter(leader *PrimaryLeader, replicas []*ReadReplica) *GatewayRouter {
	return &GatewayRouter{
		leader:       leader,
		replicas:     replicas,
		userLastEdit: make(map[string]time.Time),
	}
}

func (g *GatewayRouter) SubmitPost(userID, key, content string) {
	g.leader.WriteAsync(key, content)
	g.mu.Lock()
	g.userLastEdit[userID] = time.Now()
	g.mu.Unlock()
}

// ReadPost routes query intelligently to prevent Read-Your-Own-Writes anomaly
func (g *GatewayRouter) ReadPost(requestingUserID, authorID, key string) (DataRecord, string) {
	g.mu.RLock()
	lastEdit, hasRecentWrite := g.userLastEdit[requestingUserID]
	g.mu.RUnlock()

	// If the requesting user is the author AND modified data within the last 100ms:
	// ROUTE DIRECTLY TO PRIMARY LEADER to guarantee Read-Your-Own-Writes!
	if requestingUserID == authorID && hasRecentWrite && time.Since(lastEdit) < 100*time.Millisecond {
		rec, _ := g.leader.Read(key)
		return rec, "ROUTED_TO_PRIMARY (Read-Your-Own-Writes Protection Activated)"
	}

	// All other reads hit Read Replicas to protect Primary from query load
	rep := g.replicas[0]
	rec, _ := rep.Read(key)
	return rec, fmt.Sprintf("ROUTED_TO_READ_REPLICA_%d (Offloads Primary DB)", rep.ID)
}

func main() {
	fmt.Println("=== SD3 Database Replication: Asynchronous Lag & Read-Your-Own-Writes ===")

	// Setup: 1 Primary Leader + 1 Read Replica with 60ms replication lag
	replica := NewReadReplica(1, 60*time.Millisecond)
	leader := NewPrimaryLeader([]*ReadReplica{replica})
	router := NewGatewayRouter(leader, []*ReadReplica{replica})

	key := "post:comment:441"

	// 1. User Alice submits a new comment
	fmt.Println("\n[1] Alice submits comment 'Great system design explanation!':")
	router.SubmitPost("alice", key, "Great system design explanation!")
	fmt.Println("  Write acknowledged by Primary Leader instantly (Async replication in flight...)")

	// 2. Alice immediately reloads page (10ms after write, before replica catches up)
	time.Sleep(10 * time.Millisecond)
	recAlice, routeAlice := router.ReadPost("alice", "alice", key)
	fmt.Printf("\n[2] Alice reloads page immediately:\n")
	fmt.Printf("  Route: %s\n", routeAlice)
	fmt.Printf("  Comment Alice sees: '%s' (Version: %d)\n", recAlice.Value, recAlice.Version)

	// 3. User Bob loads the page at the same time (15ms after write)
	recBob, routeBob := router.ReadPost("bob", "alice", key)
	fmt.Printf("\n[3] Bob loads page at the exact same time:\n")
	fmt.Printf("  Route: %s\n", routeBob)
	fmt.Printf("  Comment Bob sees: '%s' (Lag window: Replica has not caught up yet!)\n", recBob.Value)

	// 4. Wait 70ms for asynchronous replication to complete
	fmt.Println("\n[4] Waiting 70ms for Read Replica to catch up...")
	time.Sleep(70 * time.Millisecond)

	recBobAfter, routeBobAfter := router.ReadPost("bob", "alice", key)
	fmt.Printf("  Bob reloads post-replication:\n")
	fmt.Printf("  Route: %s\n", routeBobAfter)
	fmt.Printf("  Comment Bob sees now: '%s' (Eventual consistency reached!)\n", recBobAfter.Value)

	fmt.Println("\n[SD3 Takeaway]: Async replication scales read capacity; Gateway routing protects users from seeing their own writes temporarily vanish due to replication lag.")
}
