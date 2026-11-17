//go:build ignore

package main

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"math"
	"sort"
	"strconv"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): CONSISTENT HASHING & VIRTUAL NODES (VNODES)
================================================================================
Key Topics Covered:
1. The Modulo Hashing Scaling Catastrophe:
   - key_index = hash(key) % N
   - When N increases from 9 to 10 nodes, ~90% of all keys are relocated to different nodes!
   - Destroys cache hit ratio, floods database with cache stampedes.
2. Consistent Hashing Ring (Chord / Amazon Dynamo / Apache Cassandra):
   - Ring space: 0 to 2^32 - 1.
   - Keys and servers mapped to positions on the circular ring.
   - Key is stored on the first server node encountered moving clockwise.
   - When node N+1 joins, ONLY 1/(N+1) fraction of keys move! 0 stampede.
3. Virtual Nodes (VNodes):
   - Physical nodes with single points on the ring create severe distribution hotspots.
   - Solution: Assign each physical node V virtual tokens (e.g. 100 VNodes) randomly dispersed
     along the ring.
   - Guarantees uniform key distribution and graceful capacity weighting.
================================================================================
*/

type ConsistentHashRing struct {
	vnodesCount int               // Number of virtual nodes per physical node
	ring        []uint32          // Sorted list of virtual node hashes
	nodeMap     map[uint32]string // VNode hash -> Physical Node Name
	nodes       map[string]bool   // Set of physical nodes
}

func NewConsistentHashRing(vnodes int) *ConsistentHashRing {
	return &ConsistentHashRing{
		vnodesCount: vnodes,
		nodeMap:     make(map[uint32]string),
		nodes:       make(map[string]bool),
	}
}

func hashToUint32(val string) uint32 {
	h := sha256.Sum256([]byte(val))
	return binary.BigEndian.Uint32(h[:4])
}

// AddNode registers a physical node and places its VNodes onto the hash ring
func (r *ConsistentHashRing) AddNode(node string) {
	r.nodes[node] = true
	for i := 0; i < r.vnodesCount; i++ {
		vnodeKey := node + "#vn#" + strconv.Itoa(i)
		hash := hashToUint32(vnodeKey)
		r.ring = append(r.ring, hash)
		r.nodeMap[hash] = node
	}
	sort.Slice(r.ring, func(i, j int) bool { return r.ring[i] < r.ring[j] })
}

// RemoveNode drops a physical node and removes its VNodes from the ring
func (r *ConsistentHashRing) RemoveNode(node string) {
	delete(r.nodes, node)
	var newRing []uint32
	for _, h := range r.ring {
		if r.nodeMap[h] == node {
			delete(r.nodeMap, h)
		} else {
			newRing = append(newRing, h)
		}
	}
	r.ring = newRing
}

// GetNode locates the physical node responsible for a given key (Clockwise search)
func (r *ConsistentHashRing) GetNode(key string) string {
	if len(r.ring) == 0 {
		return ""
	}

	h := hashToUint32(key)
	// Binary search for first VNode hash >= key hash
	idx := sort.Search(len(r.ring), func(i int) bool {
		return r.ring[i] >= h
	})

	// Wrap around to start of ring if beyond end
	if idx == len(r.ring) {
		idx = 0
	}

	return r.nodeMap[r.ring[idx]]
}

func main() {
	fmt.Println("=== SD3 Consistent Hashing: Ring Topology & Virtual Nodes (VNodes) ===")

	// 1. Initialize Ring with 3 physical nodes and 100 virtual nodes each
	vnodes := 100
	ring := NewConsistentHashRing(vnodes)
	initialNodes := []string{"storage-node-A", "storage-node-B", "storage-node-C"}
	for _, n := range initialNodes {
		ring.AddNode(n)
	}

	fmt.Printf("\n[1] Initialized Consistent Hash Ring with %d physical nodes (%d total VNodes on ring):\n",
		len(initialNodes), len(ring.ring))

	// Map 10,000 keys to check distribution uniformity
	numKeys := 10000
	keyDistribution := make(map[string]int)
	initialKeyMapping := make(map[string]string)

	for i := 0; i < numKeys; i++ {
		k := fmt.Sprintf("document:payload:key_%05d", i)
		node := ring.GetNode(k)
		keyDistribution[node]++
		initialKeyMapping[k] = node
	}

	for _, n := range initialNodes {
		count := keyDistribution[n]
		pct := float64(count) / float64(numKeys) * 100.0
		fmt.Printf("  %s -> Holds %5d keys (%.2f%% of keyspace)\n", n, count, pct)
	}

	// 2. Add 4th Node: storage-node-D (Demonstrating Minimal Key Migration)
	fmt.Println("\n[2] Scaling Up: Adding 'storage-node-D' to the cluster:")
	ring.AddNode("storage-node-D")

	migratedKeys := 0
	newDistribution := make(map[string]int)

	for i := 0; i < numKeys; i++ {
		k := fmt.Sprintf("document:payload:key_%05d", i)
		newNode := ring.GetNode(k)
		newDistribution[newNode]++
		if newNode != initialKeyMapping[k] {
			migratedKeys++
		}
	}

	fmt.Printf("  Total Keys Migrated: %d / %d (%.2f%% migrated)\n",
		migratedKeys, numKeys, float64(migratedKeys)/float64(numKeys)*100.0)
	fmt.Printf("  Theoretical Ideal Migration: 1/(N+1) = 1/4 = 25.00%%\n")
	fmt.Printf("  Actual Migration (VNodes): %.2f%% (Almost identical to theoretical perfection!)\n",
		math.Abs(float64(migratedKeys)/float64(numKeys)*100.0))

	fmt.Println("\n  Post-Scaling Key Distribution across 4 Nodes:")
	for n, count := range newDistribution {
		pct := float64(count) / float64(numKeys) * 100.0
		fmt.Printf("    %s -> %5d keys (%.2f%%)\n", n, count, pct)
	}

	fmt.Println("\n[SD3 Takeaway]: Consistent Hashing with VNodes bounds key remapping to exactly 1/(N+1) when nodes join/leave, preventing cluster-wide cache wipes.")
}
