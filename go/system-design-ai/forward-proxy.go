//go:build ignore

package main

import (
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): FORWARD PROXY & EGRESS SECURITY
================================================================================
Key Topics Covered:
1. Role of a Forward Proxy:
   - Sits on the CLIENT network boundary (e.g. corporate egress, VPN).
   - Masks client internal IP addresses from external target servers.
   - Enforces egress firewall controls (domain whitelisting, DLP - Data Loss Prevention).
   - Handles HTTP CONNECT method for transparent HTTPS TCP tunneling.
2. Forward Proxy vs Reverse Proxy:
   - Forward Proxy protects/represents the CLIENT.
   - Reverse Proxy protects/represents the SERVER.
3. CONNECT Tunneling Mechanism:
   - Client sends: CONNECT external-site.com:443 HTTP/1.1
   - Proxy establishes TCP connection with target, responds: HTTP/1.1 200 Connection Established
   - Proxy pipes raw bytes between client and server via io.Copy without inspecting TLS ciphertext.
================================================================================
*/

type ForwardProxy struct {
	allowedDomains map[string]bool
	mu             sync.RWMutex
}

func NewForwardProxy(allowed []string) *ForwardProxy {
	domains := make(map[string]bool)
	for _, d := range allowed {
		domains[strings.ToLower(d)] = true
	}
	return &ForwardProxy{allowedDomains: domains}
}

func (fp *ForwardProxy) isAllowed(host string) bool {
	h := host
	if strings.Contains(h, ":") {
		h, _, _ = net.SplitHostPort(h)
	}
	fp.mu.RLock()
	defer fp.mu.RUnlock()
	return fp.allowedDomains[strings.ToLower(h)]
}

// ServeHTTP intercepts both standard HTTP requests and HTTPS CONNECT tunnels
func (fp *ForwardProxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// 1. Security Check: Domain Filtering
	if !fp.isAllowed(r.Host) {
		fmt.Printf("  [BLOCKED EGRESS] Request to destination blocked by policy: %s\n", r.Host)
		http.Error(w, "Forbidden: Egress to domain blocked by corporate security policy", http.StatusForbidden)
		return
	}

	// 2. HTTPS Tunneling via CONNECT method
	if r.Method == http.MethodConnect {
		fp.handleHTTPSConnect(w, r)
		return
	}

	// 3. Plain HTTP Forwarding
	fp.handleHTTPForward(w, r)
}

func (fp *ForwardProxy) handleHTTPSConnect(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("  [CONNECT TUNNEL REQUEST] Client requested HTTPS tunnel to: %s\n", r.Host)
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))
}

func (fp *ForwardProxy) handleHTTPForward(w http.ResponseWriter, r *http.Request) {
	fmt.Printf("  [FORWARDING HTTP] Allowed %s to %s (Client IP Masked)\n", r.Method, r.URL.String())
	w.Header().Set("X-Forwarded-By", "Corp-Edge-Forward-Proxy/2.4")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(fmt.Sprintf(`{"status": "forwarded", "destination": "%s"}`, r.Host)))
}

func main() {
	fmt.Println("=== SD3 Forward Proxy: Egress Filtering & CONNECT Tunneling ===")

	// Allowlist only sanctioned enterprise domains
	allowedDomains := []string{"api.github.com", "internal-vault.corp", "aws.amazon.com"}
	proxy := NewForwardProxy(allowedDomains)

	fmt.Printf("  Security Egress Whitelist: %v\n\n", allowedDomains)

	// Test Case 1: Permitted domain request (api.github.com)
	fmt.Println("[1] Testing Allowed Egress Request (api.github.com):")
	reqAllowed := httptest.NewRequest("GET", "https://api.github.com/user", nil)
	reqAllowed.Host = "api.github.com"
	recAllowed := httptest.NewRecorder()
	proxy.ServeHTTP(recAllowed, reqAllowed)
	fmt.Printf("  Proxy Response Code: %d\n", recAllowed.Code)
	fmt.Printf("  Proxy Response Body: %s\n", recAllowed.Body.String())

	// Test Case 2: Blocked / Unauthorized egress request (malicious-exfiltration.com)
	fmt.Println("\n[2] Testing Blocked Egress Request (malicious-exfiltration.com):")
	reqBlocked := httptest.NewRequest("GET", "http://malicious-exfiltration.com/data", nil)
	reqBlocked.Host = "malicious-exfiltration.com"
	recBlocked := httptest.NewRecorder()
	proxy.ServeHTTP(recBlocked, reqBlocked)
	fmt.Printf("  Proxy Response Code: %d (Forbidden)\n", recBlocked.Code)
	fmt.Printf("  Proxy Response Body: %s", recBlocked.Body.String())

	// Test Case 3: HTTPS CONNECT Tunnel Handshake
	fmt.Println("\n[3] Testing HTTPS CONNECT Tunnel Negotiation:")
	reqTunnel := httptest.NewRequest(http.MethodConnect, "aws.amazon.com:443", nil)
	reqTunnel.Host = "aws.amazon.com:443"
	recTunnel := httptest.NewRecorder()
	proxy.ServeHTTP(recTunnel, reqTunnel)
	fmt.Printf("  CONNECT Tunnel Handshake Status: %d OK\n", recTunnel.Code)

	fmt.Println("\n[SD3 Takeaway]: Forward proxies enforce corporate perimeter egress security, prevent data exfiltration, and mask client topography.")
}
