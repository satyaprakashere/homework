//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): STATEFUL ARCHITECTURE & RAFT CONSENSUS LEADER ELECTION
================================================================================
Key Topics Covered:
1. When Stateful Architecture is Indispensable:
   - Persistent WebSocket Connections & Real-time Collaboration (Figma, Google Docs OT/CRDT).
   - Distributed Consensus & Metadata Coordination (etcd, ZooKeeper, CockroachDB).
   - In-memory Spatial / Physics Gaming Engines.
2. The Challenges of Stateful Architectures:
   - Cannot simply terminate/replace pods without state transfer or leader re-election.
   - Sticky Sessions / IP Hashing required at the load balancer.
3. Raft Consensus Algorithm (Leader Election Simulation):
   - Node States: Follower -> Candidate -> Leader.
   - Terms & Randomized Election Timeouts (150ms-300ms) to prevent split votes.
   - Quorum Voting: A candidate becomes Leader ONLY upon receiving votes from a majority (N/2 + 1).
   - Heartbeats: Leader sends periodic AppendEntries heartbeats to suppress new elections.
================================================================================
*/

type NodeState string

const (
	StateFollower  NodeState = "FOLLOWER"
	StateCandidate NodeState = "CANDIDATE"
	StateLeader    NodeState = "LEADER"
)

type RaftNode struct {
	ID          int
	currentTerm int
	state       NodeState
	votedFor    int
	peers       []*RaftNode
	mu          sync.Mutex
	isAlive     bool
}

func NewRaftNode(id int) *RaftNode {
	return &RaftNode{
		ID:       id,
		state:    StateFollower,
		votedFor: -1,
		isAlive:  true,
	}
}

// RequestVote RPC: Invoked by candidates to gather votes
func (n *RaftNode) RequestVote(candidateID, term int) bool {
	n.mu.Lock()
	defer n.mu.Unlock()

	if !n.isAlive {
		return false
	}

	if term > n.currentTerm {
		n.currentTerm = term
		n.state = StateFollower
		n.votedFor = -1
	}

	if (n.votedFor == -1 || n.votedFor == candidateID) && term >= n.currentTerm {
		n.votedFor = candidateID
		fmt.Printf("  [NODE %d] Voted YES for Candidate %d in Term %d\n", n.ID, candidateID, term)
		return true
	}

	return false
}

// StartElection transitions node to Candidate and requests votes from peers
func (n *RaftNode) StartElection() bool {
	n.mu.Lock()
	if !n.isAlive {
		n.mu.Unlock()
		return false
	}

	n.state = StateCandidate
	n.currentTerm++
	n.votedFor = n.ID
	term := n.currentTerm
	votes := 1 // Vote for self
	peers := n.peers
	n.mu.Unlock()

	fmt.Printf("\n  [ELECTION STARTED] Node %d timed out! Became CANDIDATE for Term %d. Requesting votes...\n", n.ID, term)

	for _, peer := range peers {
		if peer.ID != n.ID {
			if peer.RequestVote(n.ID, term) {
				votes++
			}
		}
	}

	majority := len(peers)/2 + 1
	n.mu.Lock()
	defer n.mu.Unlock()

	if votes >= majority && n.state == StateCandidate {
		n.state = StateLeader
		fmt.Printf("  >>> [LEADER ELECTED] Node %d won majority (%d/%d votes) for Term %d! <<<\n",
			n.ID, votes, len(peers), term)
		return true
	}

	fmt.Printf("  [ELECTION FAILED] Node %d did not achieve majority (%d/%d votes).\n", n.ID, votes, len(peers))
	n.state = StateFollower
	return false
}

func main() {
	fmt.Println("=== SD3 Stateful Systems: Raft Consensus Leader Election Simulation ===")

	// 1. Create 5-node cluster (Majority quorum = 5/2 + 1 = 3 votes)
	nodes := make([]*RaftNode, 5)
	for i := 0; i < 5; i++ {
		nodes[i] = NewRaftNode(i + 1)
	}
	for _, n := range nodes {
		n.peers = nodes
	}

	fmt.Println("\n[1] Normal Cluster Startup: Node 1 triggers election:")
	nodes[0].StartElection()

	// 2. Leader Crash Simulation
	fmt.Println("\n[2] Chaos Simulation: Active Leader (Node 1) Crashes (Simulating Network Partition):")
	nodes[0].isAlive = false // Kill Node 1
	fmt.Println("  Node 1 is DEAD. Heartbeats ceased!")

	// 3. Node 3 detects leader heartbeat timeout and initiates new election
	time.Sleep(20 * time.Millisecond)
	fmt.Println("\n[3] Follower Node 3 detects timeout and triggers Term 2 election:")
	nodes[2].StartElection()

	fmt.Println("\n[SD3 Takeaway]: Stateful distributed systems require consensus protocols (Raft/Paxos) to maintain a single source of truth without split-brain anomalies.")
}
