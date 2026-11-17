//go:build ignore

package main

import (
	"fmt"
	"math/rand"
	"strings"
	"sync"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DNS RESOLUTION & GLOBAL TRAFFIC ROUTING
================================================================================
Key Topics Covered:
1. Hierarchical Recursive Resolution:
   - Recursive Resolver -> Root Server -> TLD Server (.com) -> Authoritative Nameserver.
2. DNS Record Types: A, AAAA, CNAME, TXT, NS.
3. Global Traffic Management Policies:
   - Geo-DNS Routing: Maps client IP / geographic region to lowest-latency PoP.
   - Weighted Round-Robin Routing: Enables Canary deployments (e.g. 90% v1, 10% v2).
   - Health-Check Failover: Dynamically drops dead server IPs from A-record pool.
4. Caching & TTL Trade-offs:
   - Low TTL (30s): Instant failover, higher DNS server load & query latency.
   - High TTL (1hr): Caches well, but disastrous if an IP dies during the hour.

SD3 Architectural Insight: Anycast BGP vs Geo-DNS:
- GeoDNS: Resolves name to different IPs based on the client resolver's IP address.
  Flaw: EDNS Client Subnet (ECS) needed; otherwise ISP's resolver location is used!
- Anycast BGP: Single IP advertised across 100+ global data centers. Internet routers
  route packets to the topologically closest PoP automatically at the BGP level.
================================================================================
*/

type RecordType string

const (
	TypeA     RecordType = "A"     // IPv4 address
	TypeAAAA  RecordType = "AAAA"  // IPv6 address
	TypeCNAME RecordType = "CNAME" // Canonical alias
)

type DNSRecord struct {
	Name   string
	Type   RecordType
	Value  string
	TTL    int    // in seconds
	Region string // For GeoDNS: "US", "EU", "APAC", "DEFAULT"
	Weight int    // For Weighted Routing: e.g. 90 vs 10
	Healthy bool
}

// AuthoritativeNameserver holds authoritative records for a zone
type AuthoritativeNameserver struct {
	Zone    string
	records []DNSRecord
	mu      sync.RWMutex
}

func NewAuthoritativeNameserver(zone string) *AuthoritativeNameserver {
	return &AuthoritativeNameserver{Zone: zone}
}

func (ns *AuthoritativeNameserver) AddRecord(rec DNSRecord) {
	ns.mu.Lock()
	defer ns.mu.Unlock()
	rec.Healthy = true
	ns.records = append(ns.records, rec)
}

func (ns *AuthoritativeNameserver) SetHealth(ip string, healthy bool) {
	ns.mu.Lock()
	defer ns.mu.Unlock()
	for i := range ns.records {
		if ns.records[i].Value == ip {
			ns.records[i].Healthy = healthy
		}
	}
}

// ResolveGeo performs Geo-aware, health-checked resolution
func (ns *AuthoritativeNameserver) ResolveGeo(domain string, clientRegion string) []string {
	ns.mu.RLock()
	defer ns.mu.RUnlock()

	var matching []string
	var defaultFallback []string

	for _, rec := range ns.records {
		if strings.EqualFold(rec.Name, domain) && rec.Type == TypeA && rec.Healthy {
			if rec.Region == clientRegion {
				matching = append(matching, rec.Value)
			} else if rec.Region == "DEFAULT" {
				defaultFallback = append(defaultFallback, rec.Value)
			}
		}
	}

	if len(matching) > 0 {
		return matching
	}
	return defaultFallback
}

// ResolveWeighted performs weighted canary routing
func (ns *AuthoritativeNameserver) ResolveWeighted(domain string) string {
	ns.mu.RLock()
	defer ns.mu.RUnlock()

	var candidates []DNSRecord
	totalWeight := 0
	for _, rec := range ns.records {
		if strings.EqualFold(rec.Name, domain) && rec.Type == TypeA && rec.Healthy && rec.Weight > 0 {
			candidates = append(candidates, rec)
			totalWeight += rec.Weight
		}
	}

	if totalWeight == 0 || len(candidates) == 0 {
		return ""
	}

	r := rand.Intn(totalWeight)
	cumulative := 0
	for _, c := range candidates {
		cumulative += c.Weight
		if r < cumulative {
			return c.Value
		}
	}
	return candidates[0].Value
}

// -----------------------------------------------------------------------------
// RECURSIVE RESOLVER WITH CACHING
// -----------------------------------------------------------------------------

type DNSCacheEntry struct {
	IPs       []string
	ExpiresAt time.Time
}

type RecursiveResolver struct {
	authNS *AuthoritativeNameserver
	cache  map[string]DNSCacheEntry
	mu     sync.RWMutex
}

func NewRecursiveResolver(auth *AuthoritativeNameserver) *RecursiveResolver {
	return &RecursiveResolver{
		authNS: auth,
		cache:  make(map[string]DNSCacheEntry),
	}
}

func (r *RecursiveResolver) Query(domain string, clientRegion string) ([]string, bool) {
	cacheKey := fmt.Sprintf("%s:%s", domain, clientRegion)

	r.mu.RLock()
	entry, found := r.cache[cacheKey]
	r.mu.RUnlock()

	if found && time.Now().Before(entry.ExpiresAt) {
		return entry.IPs, true // Cache hit!
	}

	// Cache Miss: Simulate Recursive Tree Lookup (Root -> TLD .com -> Authoritative)
	time.Sleep(20 * time.Millisecond) // Network round trips simulation
	ips := r.authNS.ResolveGeo(domain, clientRegion)

	r.mu.Lock()
	r.cache[cacheKey] = DNSCacheEntry{
		IPs:       ips,
		ExpiresAt: time.Now().Add(200 * time.Millisecond), // short TTL for demo
	}
	r.mu.Unlock()

	return ips, false // Cache miss
}

func main() {
	fmt.Println("=== SD3 DNS Architecture: Hierarchical, Geo-DNS & Weighted Routing ===")

	authServer := NewAuthoritativeNameserver("example.com")

	// 1. Populate Geo-DNS Records
	authServer.AddRecord(DNSRecord{Name: "api.example.com", Type: TypeA, Value: "198.51.100.1 (US-East Edge)", Region: "US", TTL: 60})
	authServer.AddRecord(DNSRecord{Name: "api.example.com", Type: TypeA, Value: "198.51.200.1 (Frankfurt Edge)", Region: "EU", TTL: 60})
	authServer.AddRecord(DNSRecord{Name: "api.example.com", Type: TypeA, Value: "198.51.300.1 (Singapore Edge)", Region: "APAC", TTL: 60})
	authServer.AddRecord(DNSRecord{Name: "api.example.com", Type: TypeA, Value: "198.51.999.1 (Global Anycast)", Region: "DEFAULT", TTL: 60})

	// 2. Test Geo-DNS Routing
	fmt.Println("\n[1] Testing Geo-DNS Resolution by Client Geographic Origin:")
	regions := []string{"US", "EU", "APAC", "SA"} // SA will fallback to DEFAULT
	for _, reg := range regions {
		ips := authServer.ResolveGeo("api.example.com", reg)
		fmt.Printf("  Client in [%-4s] resolved 'api.example.com' to -> %v\n", reg, ips)
	}

	// 3. Test Recursive Resolver with TTL Caching
	fmt.Println("\n[2] Testing Recursive Resolver Caching & Latency Reduction:")
	resolver := NewRecursiveResolver(authServer)

	start := time.Now()
	ips1, hit1 := resolver.Query("api.example.com", "EU")
	t1 := time.Since(start)
	fmt.Printf("  Query 1 (Cold): %v | Cache Hit: %v | Latency: %v\n", ips1, hit1, t1)

	start = time.Now()
	ips2, hit2 := resolver.Query("api.example.com", "EU")
	t2 := time.Since(start)
	fmt.Printf("  Query 2 (Warm): %v | Cache Hit: %v | Latency: %v (Instant!)\n", ips2, hit2, t2)

	// 4. Test Weighted Canary Routing (90% v1, 10% v2)
	fmt.Println("\n[3] Testing Weighted DNS Traffic Shift (Canary Deployment):")
	canaryServer := NewAuthoritativeNameserver("shop.internal")
	canaryServer.AddRecord(DNSRecord{Name: "shop.internal", Type: TypeA, Value: "v1.0 (Stable)", Weight: 90})
	canaryServer.AddRecord(DNSRecord{Name: "shop.internal", Type: TypeA, Value: "v2.0 (Canary)", Weight: 10})

	counts := make(map[string]int)
	for i := 0; i < 1000; i++ {
		target := canaryServer.ResolveWeighted("shop.internal")
		counts[target]++
	}
	fmt.Printf("  Out of 1000 DNS queries: Stable: %d (%.1f%%) | Canary: %d (%.1f%%)\n",
		counts["v1.0 (Stable)"], float64(counts["v1.0 (Stable)"])/10.0,
		counts["v2.0 (Canary)"], float64(counts["v2.0 (Canary)"])/10.0)

	// 5. Test Active Health-Check Failover
	fmt.Println("\n[4] Testing Health-Check Dynamic Failover:")
	fmt.Println("  Killing Frankfurt Edge IP (simulating datacenter power outage)...")
	authServer.SetHealth("198.51.200.1 (Frankfurt Edge)", false)

	fallbackIPs := authServer.ResolveGeo("api.example.com", "EU")
	fmt.Printf("  Subsequent resolution for EU client fell back to: %v\n", fallbackIPs)

	fmt.Println("\n[SD3 Takeaway]: Geo-DNS directs traffic to closest edge, Weighted DNS handles Canary shifts, and health-checks provide regional disaster recovery.")
}
