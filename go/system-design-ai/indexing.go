//go:build ignore

package main

import (
	"fmt"
	"hash/fnv"
	"sort"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DATABASE INDEXING (B+ TREE vs LSM-TREE)
================================================================================
Key Topics Covered:
1. B+ Tree Indexes (PostgreSQL, MySQL InnoDB):
   - Balanced N-ary tree with high fan-out.
   - Leaf nodes contain all keys and form a doubly-linked list for lightning-fast range scans.
   - Point queries & Range queries: O(log_B N) disk seeks.
2. LSM-Tree (Log-Structured Merge-Tree) (RocksDB, Cassandra, LevelDB):
   - Optimizes Write Throughput: Turns random writes into sequential in-memory writes.
   - Architecture: MemTable (RAM) -> Flush to immutable SSTables (Disk).
   - Bloom Filters: Probabilistic data structure (O(1)) that returns "definitely not present"
     or "possibly present", preventing wasteful disk seeks for non-existent keys.
   - Compaction: Periodically merges SSTables and removes tombstones.
3. Composite Indexes & Leftmost Prefix Rule:
   - Index (tenant_id, created_at, status). Why WHERE created_at = ... cannot use the index!
================================================================================
*/

// BloomFilter provides fast probabilistic set membership checks
type BloomFilter struct {
	bits []bool
	size uint32
}

func NewBloomFilter(size uint32) *BloomFilter {
	return &BloomFilter{
		bits: make([]bool, size),
		size: size,
	}
}

func (bf *BloomFilter) hash(s string, seed uint32) uint32 {
	h := fnv.New32a()
	h.Write([]byte(fmt.Sprintf("%s:%d", s, seed)))
	return h.Sum32() % bf.size
}

func (bf *BloomFilter) Add(key string) {
	bf.bits[bf.hash(key, 1)] = true
	bf.bits[bf.hash(key, 2)] = true
	bf.bits[bf.hash(key, 3)] = true
}

func (bf *BloomFilter) MayContain(key string) bool {
	return bf.bits[bf.hash(key, 1)] &&
		bf.bits[bf.hash(key, 2)] &&
		bf.bits[bf.hash(key, 3)]
}

// SSTable represents an immutable on-disk Sorted String Table with an attached Bloom Filter
type SSTable struct {
	Level        int
	Bloom        *BloomFilter
	Data         []KVEntry
	DiskSeekCost int // Simulates disk seek overhead
}

type KVEntry struct {
	Key   string
	Value string
}

// LSMTree simulates a Log-Structured Merge-Tree
type LSMTree struct {
	memTable    map[string]string // In-memory sorted skiplist/map
	memCapacity int
	ssTables    []*SSTable
}

func NewLSMTree(memCap int) *LSMTree {
	return &LSMTree{
		memTable:    make(map[string]string),
		memCapacity: memCap,
	}
}

// Write writes to the in-memory MemTable. Flushes to SSTable when full.
func (lsm *LSMTree) Write(key, val string) {
	lsm.memTable[key] = val
	if len(lsm.memTable) >= lsm.memCapacity {
		lsm.flushMemTable()
	}
}

// flushMemTable writes Memtable to an immutable SSTable on disk
func (lsm *LSMTree) flushMemTable() {
	var entries []KVEntry
	for k, v := range lsm.memTable {
		entries = append(entries, KVEntry{Key: k, Value: v})
	}
	sort.Slice(entries, func(i, j int) bool { return entries[i].Key < entries[j].Key })

	// Build Bloom Filter for SSTable
	bloom := NewBloomFilter(1024)
	for _, e := range entries {
		bloom.Add(e.Key)
	}

	table := &SSTable{
		Level:        len(lsm.ssTables),
		Bloom:        bloom,
		Data:         entries,
		DiskSeekCost: 1,
	}
	lsm.ssTables = append(lsm.ssTables, table)
	lsm.memTable = make(map[string]string)
	fmt.Printf("  [SSTABLE FLUSHED] Flushed %d items to Disk SSTable #%d with Bloom Filter.\n",
		len(entries), table.Level)
}

// Read checks Memtable -> then SSTables using Bloom Filters to avoid disk seeks
func (lsm *LSMTree) Read(key string) (string, int, bool) {
	// 1. Check in-memory MemTable
	if val, found := lsm.memTable[key]; found {
		return val, 0, true
	}

	diskSeeks := 0
	// 2. Search SSTables from newest to oldest
	for i := len(lsm.ssTables) - 1; i >= 0; i-- {
		table := lsm.ssTables[i]

		// Bloom Filter Check: If Bloom returns false, skip disk seek entirely!
		if !table.Bloom.MayContain(key) {
			continue // Avoided expensive disk I/O!
		}

		diskSeeks++
		// Binary search inside sorted SSTable
		idx := sort.Search(len(table.Data), func(j int) bool {
			return table.Data[j].Key >= key
		})
		if idx < len(table.Data) && table.Data[idx].Key == key {
			return table.Data[idx].Value, diskSeeks, true
		}
	}

	return "", diskSeeks, false
}

// -----------------------------------------------------------------------------
// COMPOSITE INDEX & LEFTMOST PREFIX RULE DEMONSTRATION
// -----------------------------------------------------------------------------

type CompositeIndex struct {
	// Index on: (tenant_id, created_at, status)
	entries []string
}

func (ci *CompositeIndex) CanUseIndex(queryCols []string) (bool, string) {
	// Leftmost prefix check: query must start with first column "tenant_id"
	if len(queryCols) == 0 {
		return false, "Full Table Scan (no predicate)"
	}
	if queryCols[0] != "tenant_id" {
		return false, fmt.Sprintf("FULL TABLE SCAN! Query predicates %v violate Leftmost Prefix Rule (missing 'tenant_id')", queryCols)
	}
	return true, fmt.Sprintf("INDEX SEEK: Query predicates %v leverage composite index prefix!", queryCols)
}

func main() {
	fmt.Println("=== SD3 Database Indexing: LSM-Trees, Bloom Filters & Composite Indexes ===")

	// 1. LSM-Tree Write & Flush
	fmt.Println("\n[1] Testing LSM-Tree Fast Sequential Writes & SSTable Flushes:")
	lsm := NewLSMTree(3) // Flushes every 3 items

	lsm.Write("user:101", "Alice")
	lsm.Write("user:102", "Bob")
	lsm.Write("user:103", "Charlie") // Triggers flush 1

	lsm.Write("user:104", "Dave")
	lsm.Write("user:105", "Eve")
	lsm.Write("user:106", "Frank") // Triggers flush 2

	lsm.Write("user:107", "Grace") // Remains in MemTable

	// 2. LSM-Tree Read with Bloom Filter Pruning
	fmt.Println("\n[2] Testing LSM-Tree Reads with Bloom Filter Pruning:")

	// Read existing key
	val, seeks, found := lsm.Read("user:102")
	fmt.Printf("  Query 'user:102' -> Found: %v (Value: %s) | Disk Seeks: %d\n", found, val, seeks)

	// Read NON-EXISTENT key (Bloom Filter immediately skips disk seek)
	start := time.Now()
	_, seeksNonExistent, foundNonExistent := lsm.Read("user:999_non_existent")
	fmt.Printf("  Query 'user:999' -> Found: %v | Disk Seeks: %d (Bloom Filter pruned search in %v!)\n",
		foundNonExistent, seeksNonExistent, time.Since(start))

	// 3. Composite Index Leftmost Prefix Rule
	fmt.Println("\n[3] Testing Composite Index Leftmost Prefix Rule on (tenant_id, created_at, status):")
	idx := &CompositeIndex{}

	q1 := []string{"tenant_id", "created_at"}
	used1, reason1 := idx.CanUseIndex(q1)
	fmt.Printf("  Query 1 (WHERE tenant_id = 5 AND created_at > 2026): Used Index? %v -> %s\n", used1, reason1)

	q2 := []string{"created_at", "status"}
	used2, reason2 := idx.CanUseIndex(q2)
	fmt.Printf("  Query 2 (WHERE created_at > 2026 AND status = 'active'): Used Index? %v -> %s\n", used2, reason2)

	fmt.Println("\n[SD3 Takeaway]: B+ Trees excel at point lookups and range scans; LSM-Trees excel at write-heavy workloads with Bloom filters to protect read latency.")
}
