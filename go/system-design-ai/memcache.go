//go:build ignore

package main

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"sort"
	"strconv"
	"sync"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): MEMCACHED ARCHITECTURE & SLAB ALLOCATION
================================================================================
Key Topics Covered:
1. Slab Allocation Mechanism:
   - Eliminates OS memory fragmentation by pre-allocating 1MB memory pages
     divided into uniform chunk sizes (e.g. 64B, 128B, 256B, 1024B).
   - Solves external fragmentation caused by millions of arbitrary malloc/free calls.
2. Client-Side Consistent Hashing (Ketama Algorithm):
   - Memcached nodes are shared-nothing; they have zero inter-node communication.
   - The client driver hashes keys to determine which server owns the key.
3. CAS (Check-And-Set) Optimistic Concurrency Control:
   - Prevents lost updates during read-modify-write workflows.

SD3 Comparison: Memcached vs Redis:
+----------------------+--------------------------+---------------------------+
| Feature              | Memcached                | Redis                     |
+----------------------+--------------------------+---------------------------+
| Architecture         | Multi-threaded (libevent)| Single-threaded loop*     |
| Data Structures      | Raw Strings/Blobs only   | Strings, Hashes, Sets, ZSet|
| Clustering           | Client-side only (Ketama)| Redis Cluster (gossip, 16K)|
| Persistence          | None (Pure In-Memory)    | RDB snapshots + AOF log   |
| Memory Management    | Slab Allocator           | jemalloc / Custom Alloc   |
+----------------------+--------------------------+---------------------------+
================================================================================
*/

// SlabClass manages fixed-sized chunks inside pre-allocated pages
type SlabClass struct {
	chunkSize  int
	chunksFree int
	totalAlloc int
}

// SlabAllocator simulates Memcached's slab allocator
type SlabAllocator struct {
	slabClasses []SlabClass
}

func NewSlabAllocator() *SlabAllocator {
	// Slab class growth factor ~1.25x (typical Memcached standard)
	chunkSizes := []int{64, 128, 256, 512, 1024, 2048, 4096}
	classes := make([]SlabClass, len(chunkSizes))
	for i, size := range chunkSizes {
		classes[i] = SlabClass{
			chunkSize:  size,
			chunksFree: 1000, // 1000 chunks pre-allocated per slab class
			totalAlloc: 0,
		}
	}
	return &SlabAllocator{slabClasses: classes}
}

// AllocateChunk finds the smallest slab class that fits the item
func (sa *SlabAllocator) AllocateChunk(itemBytes int) (classIndex int, wastedBytes int, err error) {
	for i, sc := range sa.slabClasses {
		if itemBytes <= sc.chunkSize {
			if sc.chunksFree <= 0 {
				return -1, 0, fmt.Errorf("slab class %d (chunk size %dB) exhausted", i, sc.chunkSize)
			}
			sa.slabClasses[i].chunksFree--
			sa.slabClasses[i].totalAlloc++
			wasted := sc.chunkSize - itemBytes // Internal fragmentation
			return i, wasted, nil
		}
	}
	return -1, 0, fmt.Errorf("item size %dB exceeds largest slab class", itemBytes)
}

// MemcachedNode represents a single shared-nothing Memcached instance
type MemcachedNode struct {
	ID        string
	mu        sync.RWMutex
	store     map[string][]byte
	casTokens map[string]uint64
	casSeq    uint64
	allocator *SlabAllocator
}

func NewMemcachedNode(id string) *MemcachedNode {
	return &MemcachedNode{
		ID:        id,
		store:     make(map[string][]byte),
		casTokens: make(map[string]uint64),
		allocator: NewSlabAllocator(),
	}
}

// Set stores raw bytes, returns CAS token
func (n *MemcachedNode) Set(key string, val []byte) (uint64, error) {
	n.mu.Lock()
	defer n.mu.Unlock()

	// Allocate memory chunk via slab allocator
	_, _, err := n.allocator.AllocateChunk(len(val))
	if err != nil {
		return 0, err
	}

	n.casSeq++
	n.store[key] = val
	n.casTokens[key] = n.casSeq
	return n.casSeq, nil
}

// Gets returns value + CAS token for atomic compare-and-swap
func (n *MemcachedNode) Gets(key string) ([]byte, uint64, bool) {
	n.mu.RLock()
	defer n.mu.RUnlock()

	val, ok := n.store[key]
	if !ok {
		return nil, 0, false
	}
	return val, n.casTokens[key], true
}

// CAS (Check-And-Set): Updates key ONLY if casToken matches current version
func (n *MemcachedNode) CAS(key string, val []byte, casToken uint64) bool {
	n.mu.Lock()
	defer n.mu.Unlock()

	currToken, ok := n.casTokens[key]
	if !ok || currToken != casToken {
		return false // Abort: another client modified this key in the interim
	}

	n.casSeq++
	n.store[key] = val
	n.casTokens[key] = n.casSeq
	return true
}

// -----------------------------------------------------------------------------
// CLIENT-SIDE KETAMA CONSISTENT HASHING CLUSTER CLIENT
// -----------------------------------------------------------------------------

type MemcachedClient struct {
	nodes    map[string]*MemcachedNode
	ring     []uint32
	ringMap  map[uint32]*MemcachedNode
	vnodes   int
}

func hashKey(k string) uint32 {
	h := sha256.Sum256([]byte(k))
	return binary.BigEndian.Uint32(h[:4])
}

func NewMemcachedClient(nodes []*MemcachedNode, vnodes int) *MemcachedClient {
	c := &MemcachedClient{
		nodes:   make(map[string]*MemcachedNode),
		ringMap: make(map[uint32]*MemcachedNode),
		vnodes:  vnodes,
	}

	for _, node := range nodes {
		c.nodes[node.ID] = node
		for v := 0; v < vnodes; v++ {
			h := hashKey(node.ID + "#vnode#" + strconv.Itoa(v))
			c.ring = append(c.ring, h)
			c.ringMap[h] = node
		}
	}
	sort.Slice(c.ring, func(i, j int) bool { return c.ring[i] < c.ring[j] })
	return c
}

// GetNode locates the target Memcached server along the hash ring
func (c *MemcachedClient) GetNode(key string) *MemcachedNode {
	h := hashKey(key)
	idx := sort.Search(len(c.ring), func(i int) bool { return c.ring[i] >= h })
	if idx == len(c.ring) {
		idx = 0 // Wrap around the ring
	}
	return c.ringMap[c.ring[idx]]
}

func main() {
	fmt.Println("=== SD3 Memcached: Slab Allocation, CAS, & Client Hashing ===")

	// 1. Slab Allocation Demonstration
	allocator := NewSlabAllocator()
	testPayloads := []int{48, 110, 500, 3800}

	fmt.Println("\n[1] Testing Memcached Slab Allocator (Chunk Placement & Internal Fragmentation):")
	for _, size := range testPayloads {
		classIdx, wasted, err := allocator.AllocateChunk(size)
		if err != nil {
			fmt.Printf("  Size %dB: Error -> %v\n", size, err)
		} else {
			fmt.Printf("  Size %4dB -> Slab Class %d (Chunk: %4dB) | Internal Waste: %3dB\n",
				size, classIdx, allocator.slabClasses[classIdx].chunkSize, wasted)
		}
	}

	// 2. Client-side Consistent Hashing across 3 Memcached Nodes
	fmt.Println("\n[2] Client-Side Consistent Hash Routing (Ketama):")
	node1 := NewMemcachedNode("mc-node-1.us-east.cache:11211")
	node2 := NewMemcachedNode("mc-node-2.us-east.cache:11211")
	node3 := NewMemcachedNode("mc-node-3.us-east.cache:11211")

	client := NewMemcachedClient([]*MemcachedNode{node1, node2, node3}, 50)

	sampleKeys := []string{"session:user:101", "product:992", "feed:home:44", "cart:items:88"}
	for _, key := range sampleKeys {
		target := client.GetNode(key)
		token, _ := target.Set(key, []byte("value_for_"+key))
		fmt.Printf("  Key '%s' routed to -> [%s] (CAS Token: %d)\n", key, target.ID, token)
	}

	// 3. CAS (Check-And-Set) Atomic Update Race Simulation
	fmt.Println("\n[3] Testing CAS (Compare-And-Set) Optimistic Concurrency Control:")
	target := client.GetNode("session:user:101")
	val, token, _ := target.Gets("session:user:101")
	fmt.Printf("  Client A fetched: %s with Token: %d\n", string(val), token)

	// Simulating Client B updating the same key before Client A writes back:
	clientBToken, _ := target.Set("session:user:101", []byte("updated_by_client_B"))
	fmt.Printf("  Client B unexpectedly updated key! New Token is: %d\n", clientBToken)

	// Client A attempts to write using its stale token:
	success := target.CAS("session:user:101", []byte("stale_write_client_A"), token)
	fmt.Printf("  Client A CAS write status: %v (Rejected! Stale token prevented lost update)\n", success)

	fmt.Println("\n[SD3 Takeaway]: Memcached uses slab allocation for zero fragmentation, and client-side hashing for infinite horizontal scaling.")
}
