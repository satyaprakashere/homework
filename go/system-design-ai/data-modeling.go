//go:build ignore

package main

import (
	"fmt"
	"sort"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DATA MODELING & HYBRID FEED FAN-OUT ARCHITECTURE
================================================================================
Key Topics Covered:
1. Social Feed System Design (Twitter / Instagram / LinkedIn Timeline):
   - Fan-Out-on-Write (Push Model):
     * On tweet publish, push tweet ID to all follower timeline caches in Redis.
     * Read path: O(1) instant lookup from Redis list (LRANGE home:timeline 0 20).
     * The Celebrity Problem: A celebrity with 100M followers triggers 100,000,000 writes,
       exhausting write queues and spiking latency!
   - Fan-Out-on-Read (Pull Model):
     * Tweets stored in author's table. On feed refresh, fetch recent tweets from all followed users.
     * Write path: O(1). Read path: Expensive multi-way merge sort.
   - The Hybrid Solution (Industry Standard):
     * Standard users (< 25,000 followers): Push model (Fan-out on write).
     * Celebrity users (> 25,000 followers): Pull model (Merged on read).
================================================================================
*/

type Tweet struct {
	ID        int
	AuthorID  string
	Content   string
	CreatedAt time.Time
}

// UserAccount models social network user profile and follower metrics
type UserAccount struct {
	UserID        string
	FollowerCount int
	IsCelebrity   bool
}

// SocialFeedSystem implements the hybrid fan-out architecture
type SocialFeedSystem struct {
	users             map[string]*UserAccount
	userTweets        map[string][]Tweet   // AuthorID -> Tweets
	inboxTimelines    map[string][]Tweet   // FollowerID -> Timeline Cache (Push)
	following         map[string][]string  // UserID -> Followed Users
	mu                sync.RWMutex
	pushedWritesCount int
}

func NewSocialFeedSystem() *SocialFeedSystem {
	return &SocialFeedSystem{
		users:          make(map[string]*UserAccount),
		userTweets:     make(map[string][]Tweet),
		inboxTimelines: make(map[string][]Tweet),
		following:      make(map[string][]string),
	}
}

func (s *SocialFeedSystem) RegisterUser(userID string, followerCount int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.users[userID] = &UserAccount{
		UserID:        userID,
		FollowerCount: followerCount,
		IsCelebrity:   followerCount >= 10000, // Celebrity threshold: 10,000+
	}
}

func (s *SocialFeedSystem) Follow(follower, followee string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.following[follower] = append(s.following[follower], followee)
}

// PostTweet implements Hybrid Fan-Out logic
func (s *SocialFeedSystem) PostTweet(authorID, content string) Tweet {
	s.mu.Lock()
	defer s.mu.Unlock()

	author := s.users[authorID]
	tweet := Tweet{
		ID:        len(s.userTweets[authorID]) + 1,
		AuthorID:  authorID,
		Content:   content,
		CreatedAt: time.Now(),
	}
	s.userTweets[authorID] = append(s.userTweets[authorID], tweet)

	// HYBRID FAN-OUT DECISION:
	if author.IsCelebrity {
		fmt.Printf("  [POST TWEET] %s is a CELEBRITY (%d followers). SKIPPING Fan-out-on-write to protect queues!\n",
			authorID, author.FollowerCount)
		return tweet
	}

	// Standard User: Fan-out on write (push to all followers)
	fmt.Printf("  [POST TWEET] %s is a regular user. Executing Fan-out-on-write to followers...\n", authorID)
	for followerID, followedList := range s.following {
		for _, f := range followedList {
			if f == authorID {
				s.inboxTimelines[followerID] = append([]Tweet{tweet}, s.inboxTimelines[followerID]...)
				s.pushedWritesCount++
			}
		}
	}
	return tweet
}

// GetHomeFeed merges pushed inbox timeline with pulled celebrity tweets (Hybrid Merge)
func (s *SocialFeedSystem) GetHomeFeed(userID string, limit int) []Tweet {
	s.mu.RLock()
	defer s.mu.RUnlock()

	// 1. Get pre-computed timeline from inbox (from regular users via push)
	timeline := append([]Tweet(nil), s.inboxTimelines[userID]...)

	// 2. Dynamically pull tweets from followed CELEBRITY accounts
	followed := s.following[userID]
	for _, authorID := range followed {
		author := s.users[authorID]
		if author.IsCelebrity {
			// Pull latest tweets from celebrity table
			celebTweets := s.userTweets[authorID]
			timeline = append(timeline, celebTweets...)
		}
	}

	// 3. Merge & Sort by timestamp descending
	sort.Slice(timeline, func(i, j int) bool {
		return timeline[i].CreatedAt.After(timeline[j].CreatedAt)
	})

	if len(timeline) > limit {
		timeline = timeline[:limit]
	}

	return timeline
}

func main() {
	fmt.Println("=== SD3 Data Modeling: Twitter Feed Hybrid Fan-Out Architecture ===")

	sys := NewSocialFeedSystem()

	// 1. Setup Accounts
	sys.RegisterUser("elon_musk", 150000000) // Celebrity (> 10k followers)
	sys.RegisterUser("alice_dev", 250)       // Regular user
	sys.RegisterUser("bob_engineer", 400)   // Regular user
	sys.RegisterUser("charlie_user", 50)    // Regular reader

	// Charlie follows both Alice (regular) and Elon (celebrity)
	sys.Follow("charlie_user", "alice_dev")
	sys.Follow("charlie_user", "elon_musk")

	// 2. Regular User Alice Tweets
	fmt.Println("\n[1] Regular User Alice Tweets:")
	sys.PostTweet("alice_dev", "Just released a new Go microservice!")

	// 3. Celebrity Elon Musk Tweets
	fmt.Println("\n[2] Celebrity Elon Musk Tweets:")
	sys.PostTweet("elon_musk", "Starship successfully reached orbit!")

	// 4. Charlie Reads Home Feed (Hybrid Merge in action)
	fmt.Println("\n[3] Charlie fetches Home Feed (Hybrid Merge: Pre-computed Push + Dynamic Celeb Pull):")
	feed := sys.GetHomeFeed("charlie_user", 10)

	for rank, t := range feed {
		fmt.Printf("  #%d: [%-12s] %s\n", rank+1, t.AuthorID, t.Content)
	}

	fmt.Println("\n[SD3 Takeaway]: Hybrid Fan-Out combines O(1) push timelines for 99% of users with dynamic on-demand pull for celebrity accounts, solving the celebrity hotspot problem.")
}
