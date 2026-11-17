//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DATABASE STORAGE ENGINES & WRITE-AHEAD LOG (WAL)
================================================================================
Key Topics Covered:
1. Write-Ahead Logging (WAL) & ARIES Crash Recovery:
   - Fundamental Rule: WAL record MUST be flushed to non-volatile disk BEFORE the
     corresponding dirty page in the buffer pool can be written to disk.
   - Sequential disk I/O (append-only) is orders of magnitude faster than random I/O.
2. Buffer Pool / Page Cache Architecture:
   - Pages cached in RAM (e.g. 8KB or 16KB pages).
   - Dirty pages marked in memory and periodically flushed asynchronously by page flusher.
3. Crash Recovery (Analysis, Redo, Undo):
   - Replays WAL from the last Checkpoint LSN (Log Sequence Number) to reconstruct memory state.
================================================================================
*/

type WALRecord struct {
	LSN   uint64 // Log Sequence Number
	Key   string
	Value string
	Op    string // "INSERT", "UPDATE", "DELETE", "CHECKPOINT"
}

// WriteAheadLog simulates append-only sequential disk log
type WriteAheadLog struct {
	mu      sync.Mutex
	entries []WALRecord
	lastLSN uint64
}

func NewWAL() *WriteAheadLog {
	return &WriteAheadLog{}
}

func (w *WriteAheadLog) Append(op, key, val string) uint64 {
	w.mu.Lock()
	defer w.mu.Unlock()

	w.lastLSN++
	rec := WALRecord{
		LSN:   w.lastLSN,
		Key:   key,
		Value: val,
		Op:    op,
	}
	w.entries = append(w.entries, rec)
	return w.lastLSN
}

// StorageEngine simulates in-memory Buffer Pool backed by WAL and Disk Checkpoints
type StorageEngine struct {
	wal           *WriteAheadLog
	bufferPool    map[string]string // RAM page cache (volatile)
	diskStorage   map[string]string // Persistent disk pages (non-volatile)
	checkpointLSN uint64
	mu            sync.RWMutex
}

func NewStorageEngine(wal *WriteAheadLog) *StorageEngine {
	return &StorageEngine{
		wal:         wal,
		bufferPool:  make(map[string]string),
		diskStorage: make(map[string]string),
	}
}

// Set performs WAL write first, then updates volatile buffer pool
func (e *StorageEngine) Set(key, value string) uint64 {
	// 1. Write to WAL first (Sequential append)
	lsn := e.wal.Append("SET", key, value)

	// 2. Update Buffer Pool in RAM (marks page dirty)
	e.mu.Lock()
	e.bufferPool[key] = value
	e.mu.Unlock()

	return lsn
}

// Checkpoint flushes dirty pages from RAM buffer pool to persistent disk
func (e *StorageEngine) Checkpoint() {
	e.mu.Lock()
	defer e.mu.Unlock()

	// Flush RAM state to Disk
	for k, v := range e.bufferPool {
		e.diskStorage[k] = v
	}
	e.checkpointLSN = e.wal.lastLSN
	e.wal.Append("CHECKPOINT", "", "")
	fmt.Printf("  [CHECKPOINT COMPLETED] Flushed dirty pages to disk at LSN: %d\n", e.checkpointLSN)
}

// Crash simulates sudden server power loss (wipes volatile RAM buffer pool completely!)
func (e *StorageEngine) Crash() {
	e.mu.Lock()
	defer e.mu.Unlock()
	e.bufferPool = make(map[string]string) // RAM wiped!
	fmt.Println("  [SERVER CRASH] Power loss! Volatile RAM Buffer Pool is completely wiped!")
}

// Recover replays the WAL from the last checkpoint LSN to rebuild the buffer pool
func (e *StorageEngine) Recover() int {
	e.mu.Lock()
	defer e.mu.Unlock()

	// 1. Restore from last disk checkpoint
	for k, v := range e.diskStorage {
		e.bufferPool[k] = v
	}

	// 2. Replay WAL entries created AFTER the checkpoint
	replayed := 0
	for _, entry := range e.wal.entries {
		if entry.LSN > e.checkpointLSN && entry.Op == "SET" {
			e.bufferPool[entry.Key] = entry.Value
			replayed++
			fmt.Printf("  [REDO LOG REPLAY] Replaying LSN %d: %s = %s\n", entry.LSN, entry.Key, entry.Value)
		}
	}
	return replayed
}

func (e *StorageEngine) Get(key string) (string, bool) {
	e.mu.RLock()
	defer e.mu.RUnlock()
	val, exists := e.bufferPool[key]
	return val, exists
}

func main() {
	fmt.Println("=== SD3 Database Storage Engine: WAL & ARIES Crash Recovery ===")

	wal := NewWAL()
	engine := NewStorageEngine(wal)

	// 1. Normal Operations
	fmt.Println("\n[1] Writing Transactions (Appended to WAL + Dirty in Buffer Pool):")
	engine.Set("account:1", "$100")
	engine.Set("account:2", "$250")
	fmt.Printf("  account:1 = %s, account:2 = %s\n", "$100", "$250")

	// 2. Checkpoint
	fmt.Println("\n[2] Triggering Periodic Background Checkpoint:")
	engine.Checkpoint()

	// 3. Transactions written AFTER the checkpoint
	fmt.Println("\n[3] Writing More Transactions after Checkpoint (Only in WAL + RAM):")
	engine.Set("account:3", "$500")
	engine.Set("account:1", "$120") // updated account 1
	fmt.Println("  account:3 = $500, account:1 = $120 written.")

	// 4. Simulate Sudden Power Outage / Server Crash
	fmt.Println("\n[4] Simulating Catastrophic Crash:")
	engine.Crash()

	if _, ok := engine.Get("account:3"); !ok {
		fmt.Println("  Verified: account:3 is missing from RAM buffer pool after crash!")
	}

	// 5. Recovery Sequence
	fmt.Println("\n[5] Executing Database Crash Recovery Sequence:")
	start := time.Now()
	replayed := engine.Recover()
	fmt.Printf("  Recovery finished in %v. Replayed %d transactions from WAL.\n", time.Since(start), replayed)

	// Verify all data restored with zero data loss!
	v1, _ := engine.Get("account:1")
	v2, _ := engine.Get("account:2")
	v3, _ := engine.Get("account:3")
	fmt.Printf("  Post-recovery state: account:1 = %s, account:2 = %s, account:3 = %s\n", v1, v2, v3)

	fmt.Println("\n[SD3 Takeaway]: The Write-Ahead Log (WAL) guarantees Durability (the 'D' in ACID); Checkpoints bound crash recovery time.")
}
