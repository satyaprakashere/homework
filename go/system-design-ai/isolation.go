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
SYSTEM DESIGN INTERVIEW (SD3): TRANSACTION ISOLATION LEVELS & ANOMALIES (MVCC)
================================================================================
Key Topics Covered:
1. ANSI SQL Isolation Levels:
   +------------------+------------+--------------------+--------------+------------+
   | Isolation Level  | Dirty Read | Non-Repeatable Read| Phantom Read | Write Skew |
   +------------------+------------+--------------------+--------------+------------+
   | Read Uncommitted | YES        | YES                | YES          | YES        |
   | Read Committed   | NO         | YES                | YES          | YES        |
   | Repeatable Read  | NO         | NO                 | YES (in lock)| YES        |
   | Serializable     | NO         | NO                 | NO           | NO         |
   +------------------+------------+--------------------+--------------+------------+
2. Multi-Version Concurrency Control (MVCC) Snapshot Isolation:
   - PostgreSQL / MySQL InnoDB MVCC: Every row has creation/deletion transaction IDs (xmin/xmax).
   - Non-blocking reads: Readers do NOT block writers; writers do NOT block readers!
3. The Subtle Write Skew Anomaly:
   - Two concurrent transactions satisfy constraint independently, but combined result breaks invariant.
   - Example: Hospital On-Call schedule (Invariant: at least 1 doctor on call).
================================================================================
*/

// MVCCVersion represents an immutable row version
type MVCCVersion struct {
	Value     string
	CreatedTx uint64
	ExpiredTx uint64 // 0 if currently active
}

// MVCCDatabase simulates a multi-version concurrency control storage engine
type MVCCDatabase struct {
	records map[string][]MVCCVersion
	txSeq   uint64
	mu      sync.RWMutex
}

func NewMVCCDatabase() *MVCCDatabase {
	return &MVCCDatabase{
		records: make(map[string][]MVCCVersion),
	}
}

func (db *MVCCDatabase) BeginTx() uint64 {
	db.mu.Lock()
	defer db.mu.Unlock()
	db.txSeq++
	return db.txSeq
}

// SnapshotRead reads the latest version committed at or before the transaction's snapshot ID
// This guarantees Repeatable Read without locking rows!
func (db *MVCCDatabase) SnapshotRead(txID uint64, key string) (string, bool) {
	db.mu.RLock()
	defer db.mu.RUnlock()

	versions, exists := db.records[key]
	if !exists {
		return "", false
	}

	// Search versions visible to this transaction's snapshot
	for i := len(versions) - 1; i >= 0; i-- {
		v := versions[i]
		if v.CreatedTx <= txID && (v.ExpiredTx == 0 || v.ExpiredTx > txID) {
			return v.Value, true
		}
	}
	return "", false
}

// Write creates a new version with the transaction's ID
func (db *MVCCDatabase) Write(txID uint64, key, value string) {
	db.mu.Lock()
	defer db.mu.Unlock()

	// Expire previous active version
	versions := db.records[key]
	for i := range versions {
		if versions[i].ExpiredTx == 0 {
			versions[i].ExpiredTx = txID
		}
	}

	// Append new version
	db.records[key] = append(versions, MVCCVersion{
		Value:     value,
		CreatedTx: txID,
		ExpiredTx: 0,
	})
}

// -----------------------------------------------------------------------------
// WRITE SKEW ANOMALY DEMONSTRATION (HOSPITAL ON-CALL DOCTORS)
// -----------------------------------------------------------------------------

type DoctorOnCall struct {
	DoctorAliceOnCall atomic.Bool
	DoctorBobOnCall   atomic.Bool
}

func main() {
	fmt.Println("=== SD3 Transaction Isolation: MVCC Snapshot Isolation & Write Skew ===")

	db := NewMVCCDatabase()

	// Initial State: Account balance = $1000 at Tx 1
	tx0 := db.BeginTx()
	db.Write(tx0, "account:1", "$1000")

	// 1. Snapshot Isolation (Repeatable Read without row locks)
	fmt.Println("\n[1] Demonstrating MVCC Snapshot Isolation (Non-Repeatable Read Prevention):")
	txReader := db.BeginTx()
	val1, _ := db.SnapshotRead(txReader, "account:1")
	fmt.Printf("  Tx Reader (TxID: %d) first read: %s\n", txReader, val1)

	// Concurrent Writer updates balance to $2000 at Tx 3
	txWriter := db.BeginTx()
	db.Write(txWriter, "account:1", "$2000")
	fmt.Printf("  Tx Writer (TxID: %d) updated account:1 to $2000 and COMMITTED!\n", txWriter)

	// Reader reads AGAIN using its initial snapshot TxID
	val2, _ := db.SnapshotRead(txReader, "account:1")
	fmt.Printf("  Tx Reader (TxID: %d) second read: %s (STILL $1000! Repeatable Read maintained via MVCC)\n",
		txReader, val2)

	// A new transaction started now will see the new version
	txNew := db.BeginTx()
	val3, _ := db.SnapshotRead(txNew, "account:1")
	fmt.Printf("  New Tx (TxID: %d) sees fresh committed version: %s\n", txNew, val3)

	// 2. The Write Skew Anomaly under Snapshot Isolation
	fmt.Println("\n[2] Demonstrating Write Skew Anomaly (Requires SERIALIZABLE to prevent):")
	fmt.Println("  Invariant: At least ONE doctor must remain on call at all times.")
	hospital := &DoctorOnCall{}
	hospital.DoctorAliceOnCall.Store(true)
	hospital.DoctorBobOnCall.Store(true)
	fmt.Println("  Initial: Alice = ON CALL, Bob = ON CALL (Total: 2 on call)")

	// Transaction 1: Alice wants to take leave
	// Alice checks: Is Bob on call? Yes (Bob = true). So Alice sets Alice = false.
	// Transaction 2: Bob concurrently wants to take leave
	// Bob checks: Is Alice on call? Yes (Alice = true). So Bob sets Bob = false.
	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		// Alice checks invariant
		if hospital.DoctorBobOnCall.Load() {
			time.Sleep(10 * time.Millisecond)
			hospital.DoctorAliceOnCall.Store(false)
			fmt.Println("  Alice took leave (saw Bob was on call)")
		}
	}()

	go func() {
		defer wg.Done()
		// Bob checks invariant
		if hospital.DoctorAliceOnCall.Load() {
			time.Sleep(10 * time.Millisecond)
			hospital.DoctorBobOnCall.Store(false)
			fmt.Println("  Bob took leave (saw Alice was on call)")
		}
	}()

	wg.Wait()

	fmt.Printf("  Result: Alice On Call: %v | Bob On Call: %v\n",
		hospital.DoctorAliceOnCall.Load(), hospital.DoctorBobOnCall.Load())
	fmt.Println("  CRITICAL ANOMALY: ZERO doctors on call! Invariant violated due to Write Skew!")
	fmt.Println("  Fix: Must use SERIALIZABLE isolation level (SSI - Serializable Snapshot Isolation) or SELECT ... FOR UPDATE.")

	fmt.Println("\n[SD3 Takeaway]: MVCC enables lock-free repeatable reads via snapshots; SSI is required to prevent Write Skew anomalies.")
}
