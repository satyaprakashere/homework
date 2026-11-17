//go:build ignore

package main

import (
	"fmt"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DENORMALIZATION & CQRS MATERIALIZED VIEWS
================================================================================
Key Topics Covered:
1. When & Why to Denormalize at Scale:
   - Normalized OLTP schemas require multi-table JOINs across sharded network nodes.
   - At 100k QPS, running SELECT COUNT(*) FROM likes WHERE post_id = ... will melt any database.
   - Denormalization pre-aggregates counters (like_count, comment_count) and embeds author names.
2. CQRS (Command Query Responsibility Segregation):
   - Command (Write) Model: Normalized 3NF (optimized for ACID transactions and zero update anomalies).
   - Query (Read) Model: Denormalized flat documents (optimized for O(1) single-key reads).
3. Transactional Outbox Pattern + Change Data Capture (CDC):
   - Solves the dual-write race condition: write entity + outbox event in 1 local ACID transaction.
   - Background worker tails outbox log and updates denormalized read views asynchronously.
================================================================================
*/

// WriteModelPost represents normalized OLTP row in primary DB
type WriteModelPost struct {
	ID        int
	AuthorID  int
	Title     string
	Content   string
	CreatedAt time.Time
}

type WriteModelAuthor struct {
	ID       int
	Username string
	Verified bool
}

// DenormalizedPostView represents read-optimized flat document (e.g. in Elasticsearch / DynamoDB)
type DenormalizedPostView struct {
	PostID         int       `json:"postId"`
	Title          string    `json:"title"`
	AuthorUsername string    `json:"authorUsername"` // Pre-joined! No join needed on read
	AuthorVerified bool      `json:"authorVerified"` // Pre-joined!
	LikesCount     int       `json:"likesCount"`     // Pre-aggregated counter!
	CommentsCount  int       `json:"commentsCount"`  // Pre-aggregated counter!
	LastSyncedAt   time.Time `json:"lastSyncedAt"`
}

// CQRSSystem coordinates normalized writes and denormalized read projections
type CQRSSystem struct {
	// Write Side (Normalized OLTP)
	authorsDB map[int]WriteModelAuthor
	postsDB   map[int]WriteModelPost
	likesDB   map[int][]int // PostID -> Slice of UserIDs

	// Read Side (Denormalized Materialized Views)
	readViews map[int]DenormalizedPostView

	outboxQueue chan int // Outbox event channel (PostID)
	mu          sync.RWMutex
}

func NewCQRSSystem() *CQRSSystem {
	sys := &CQRSSystem{
		authorsDB:   make(map[int]WriteModelAuthor),
		postsDB:     make(map[int]WriteModelPost),
		likesDB:     make(map[int][]int),
		readViews:   make(map[int]DenormalizedPostView),
		outboxQueue: make(chan int, 100),
	}
	// Start asynchronous CDC outbox processor
	go sys.processOutboxEvents()
	return sys
}

// CreatePost executes normalized ACID write and enqueues outbox event
func (s *CQRSSystem) CreatePost(postID, authorID int, title, content string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// 1. Write to normalized write table
	s.postsDB[postID] = WriteModelPost{
		ID:        postID,
		AuthorID:  authorID,
		Title:     title,
		Content:   content,
		CreatedAt: time.Now(),
	}

	// 2. Transactional Outbox event
	s.outboxQueue <- postID
	fmt.Printf("  [Write Command] Inserted Post #%d to 3NF Normalized Table.\n", postID)
}

// AddLike updates normalized table and enqueues CDC sync
func (s *CQRSSystem) AddLike(postID, userID int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.likesDB[postID] = append(s.likesDB[postID], userID)
	s.outboxQueue <- postID
}

// processOutboxEvents simulates background CDC (e.g. Debezium / Kafka Connect)
// building the denormalized read model
func (s *CQRSSystem) processOutboxEvents() {
	for postID := range s.outboxQueue {
		time.Sleep(10 * time.Millisecond) // Simulated async projection pipeline latency

		s.mu.Lock()
		post := s.postsDB[postID]
		author := s.authorsDB[post.AuthorID]
		likes := len(s.likesDB[postID])

		// Project flat denormalized document
		s.readViews[postID] = DenormalizedPostView{
			PostID:         postID,
			Title:          post.Title,
			AuthorUsername: author.Username,
			AuthorVerified: author.Verified,
			LikesCount:     likes,
			CommentsCount:  0,
			LastSyncedAt:   time.Now(),
		}
		s.mu.Unlock()
		fmt.Printf("  [CDC Projection] Rebuilt Denormalized Read View for Post #%d (Likes: %d)\n", postID, likes)
	}
}

// ReadPostQuery executes high-speed O(1) read from denormalized store (Zero joins!)
func (s *CQRSSystem) ReadPostQuery(postID int) (DenormalizedPostView, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	view, found := s.readViews[postID]
	return view, found
}

func main() {
	fmt.Println("=== SD3 Denormalization: CQRS & Materialized Read Projections ===")

	cqrs := NewCQRSSystem()

	// Setup Author
	cqrs.mu.Lock()
	cqrs.authorsDB[101] = WriteModelAuthor{ID: 101, Username: "prakash_architect", Verified: true}
	cqrs.mu.Unlock()

	// 1. Create Post
	fmt.Println("\n[1] Client Publishes Post:")
	cqrs.CreatePost(1, 101, "Designing High-Scale Systems", "Full architecture blueprint...")

	// 2. Add Likes
	fmt.Println("\n[2] Users Like the Post:")
	cqrs.AddLike(1, 201)
	cqrs.AddLike(1, 202)
	cqrs.AddLike(1, 203)

	// Wait for CDC pipeline to synchronize denormalized projection
	time.Sleep(50 * time.Millisecond)

	// 3. Read Query Path (Instant O(1) single-key lookup)
	fmt.Println("\n[3] Reading from Denormalized Store (ZERO JOINs, pre-aggregated):")
	start := time.Now()
	view, found := cqrs.ReadPostQuery(1)
	elapsed := time.Since(start)

	if found {
		fmt.Printf("  Read Latency: %v\n", elapsed)
		fmt.Printf("  Post Title      : %s\n", view.Title)
		fmt.Printf("  Author Username : %s (Verified: %v - Pre-joined!)\n", view.AuthorUsername, view.AuthorVerified)
		fmt.Printf("  Total Likes     : %d (Pre-aggregated count, NO SELECT COUNT(*) required!)\n", view.LikesCount)
	}

	fmt.Println("\n[SD3 Takeaway]: Denormalization trades redundant storage and eventual consistency for sub-millisecond read latency without costly relational joins.")
}
