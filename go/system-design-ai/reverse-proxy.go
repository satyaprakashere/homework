//go:build ignore

package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"net/url"
	"strings"
	"sync/atomic"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): REVERSE PROXY & TRAFFIC INGRESS
================================================================================
Key Topics Covered:
1. Reverse Proxy Mechanics:
   - Shield backend topology; client believes Reverse Proxy IS the actual server.
   - SSL/TLS Termination at Edge.
   - Upstream Path-Based Routing (/orders -> Order Service, /users -> User Service).
   - Header Enrichment: X-Forwarded-For, X-Forwarded-Proto, X-Request-ID (Tracing).
2. Upstream Transport & Failure Handling:
   - Custom http.RoundTripper for connection pooling, retries, and circuit breaking.
   - Graceful 502 Bad Gateway / 503 handling.
   - Custom Director and ModifyResponse hooks using httputil.ReverseProxy.

SD3 Architectural Insights: Reverse Proxy vs API Gateway:
- Reverse Proxy (NGINX / HAProxy / Envoy):
  Focuses on raw networking, TLS termination, HTTP pipelining, caching, routing.
- API Gateway (Kong / Apisix / AWS API Gateway):
  Higher abstraction layer: Auth (JWT/OAuth2), Rate Limiting, Request Validation,
  GraphQL Stitching, Monetization/Billing.
================================================================================
*/

// MockUpstreamTransport intercepts requests in-memory without needing OS TCP sockets
type MockUpstreamTransport struct {
	userServiceCalls  atomic.Uint64
	orderServiceCalls atomic.Uint64
}

func (t *MockUpstreamTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	traceID := req.Header.Get("X-Request-ID")
	xff := req.Header.Get("X-Forwarded-For")
	proto := req.Header.Get("X-Forwarded-Proto")

	var body string
	statusCode := http.StatusOK

	if strings.Contains(req.URL.Host, "user-service") {
		t.userServiceCalls.Add(1)
		body = fmt.Sprintf(`{"service": "user-microservice", "traceId": "%s", "clientIP": "%s", "proto": "%s"}`,
			traceID, xff, proto)
	} else if strings.Contains(req.URL.Host, "order-service") {
		t.orderServiceCalls.Add(1)
		body = fmt.Sprintf(`{"service": "order-microservice", "traceId": "%s", "status": "active"}`, traceID)
	} else if strings.Contains(req.URL.Host, "dead-service") {
		return nil, fmt.Errorf("connection refused: upstream unreachable")
	} else {
		body = `{"service": "static-landing-page"}`
	}

	header := make(http.Header)
	header.Set("Content-Type", "application/json")

	return &http.Response{
		StatusCode: statusCode,
		Status:     fmt.Sprintf("%d OK", statusCode),
		Header:     header,
		Body:       io.NopCloser(bytes.NewBufferString(body)),
		Request:    req,
	}, nil
}

type UpstreamRouter struct {
	userSvcURL    *url.URL
	orderSvcURL   *url.URL
	defaultSvcURL *url.URL
	deadSvcURL    *url.URL
	transport     *MockUpstreamTransport
	requestCount  atomic.Uint64
}

func NewUpstreamRouter() *UpstreamRouter {
	uUser, _ := url.Parse("http://user-service.internal")
	uOrder, _ := url.Parse("http://order-service.internal")
	uDef, _ := url.Parse("http://default-service.internal")
	uDead, _ := url.Parse("http://dead-service.internal")

	return &UpstreamRouter{
		userSvcURL:    uUser,
		orderSvcURL:   uOrder,
		defaultSvcURL: uDef,
		deadSvcURL:    uDead,
		transport:     &MockUpstreamTransport{},
	}
}

// BuildReverseProxy constructs an httputil.ReverseProxy with routing & tracing injection
func (r *UpstreamRouter) BuildReverseProxy() *httputil.ReverseProxy {
	director := func(req *http.Request) {
		reqID := fmt.Sprintf("req-uuid-%06d", r.requestCount.Add(1))

		// 1. Path-based upstream destination dispatch
		var target *url.URL
		if strings.HasPrefix(req.URL.Path, "/users") {
			target = r.userSvcURL
		} else if strings.HasPrefix(req.URL.Path, "/orders") {
			target = r.orderSvcURL
		} else if strings.HasPrefix(req.URL.Path, "/crash") {
			target = r.deadSvcURL
		} else {
			target = r.defaultSvcURL
		}

		req.URL.Scheme = target.Scheme
		req.URL.Host = target.Host

		// 2. Header Enrichment: Provenance & Distributed Tracing
		req.Header.Set("X-Request-ID", reqID)
		req.Header.Set("X-Forwarded-Proto", "https")
		if clientIP := req.RemoteAddr; clientIP != "" {
			existingXFF := req.Header.Get("X-Forwarded-For")
			if existingXFF != "" {
				req.Header.Set("X-Forwarded-For", existingXFF+", "+clientIP)
			} else {
				req.Header.Set("X-Forwarded-For", clientIP)
			}
		}

		fmt.Printf("  [ROUTED] %-6s %-15s -> Upstream [%s] (TraceID: %s)\n",
			req.Method, req.URL.Path, target.Host, reqID)
	}

	// ModifyResponse hook: Inject security & latency headers back to client
	modifyResponse := func(resp *http.Response) error {
		resp.Header.Set("X-Served-By", "Edge-Reverse-Proxy-Cluster")
		resp.Header.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		return nil
	}

	// ErrorHandler hook: Graceful 502 Bad Gateway
	errorHandler := func(w http.ResponseWriter, req *http.Request, err error) {
		fmt.Printf("  [UPSTREAM ERROR] Failed to connect to backend: %v\n", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadGateway)
		_, _ = w.Write([]byte(`{"error": "Bad Gateway", "message": "Upstream service unreachable"}`))
	}

	return &httputil.ReverseProxy{
		Director:       director,
		Transport:      r.transport,
		ModifyResponse: modifyResponse,
		ErrorHandler:   errorHandler,
	}
}

func main() {
	fmt.Println("=== SD3 Reverse Proxy: Path Routing, Header Injection & TLS Termination ===")

	router := NewUpstreamRouter()
	reverseProxy := router.BuildReverseProxy()

	// 1. Route Request to User Microservice
	fmt.Println("\n[1] Client Request: GET /users/101:")
	req1 := httptest.NewRequest("GET", "/users/101", nil)
	req1.RemoteAddr = "192.0.2.45"
	rec1 := httptest.NewRecorder()
	reverseProxy.ServeHTTP(rec1, req1)
	fmt.Printf("  Response Status: %d\n", rec1.Code)
	fmt.Printf("  Response Headers: X-Served-By: %s | HSTS: %s\n",
		rec1.Header().Get("X-Served-By"), rec1.Header().Get("Strict-Transport-Security"))
	fmt.Printf("  Response Body: %s\n", rec1.Body.String())

	// 2. Route Request to Order Microservice
	fmt.Println("\n[2] Client Request: POST /orders/checkout:")
	req2 := httptest.NewRequest("POST", "/orders/checkout", nil)
	req2.RemoteAddr = "203.0.113.88"
	rec2 := httptest.NewRecorder()
	reverseProxy.ServeHTTP(rec2, req2)
	fmt.Printf("  Response Status: %d\n", rec2.Code)
	fmt.Printf("  Response Body: %s\n", rec2.Body.String())

	// 3. Fallback to Default Service
	fmt.Println("\n[3] Client Request: GET /about-us:")
	req3 := httptest.NewRequest("GET", "/about-us", nil)
	rec3 := httptest.NewRecorder()
	reverseProxy.ServeHTTP(rec3, req3)
	fmt.Printf("  Response Status: %d\n", rec3.Code)
	fmt.Printf("  Response Body: %s\n", rec3.Body.String())

	// 4. Dead Backend Handling (502 Bad Gateway)
	fmt.Println("\n[4] Request to Dead Backend (/crash):")
	reqDead := httptest.NewRequest("GET", "/crash", nil)
	recDead := httptest.NewRecorder()
	reverseProxy.ServeHTTP(recDead, reqDead)
	fmt.Printf("  Response Status: %d\n", recDead.Code)
	fmt.Printf("  Response Body: %s\n", recDead.Body.String())

	fmt.Println("\n[SD3 Takeaway]: Reverse Proxies unify backend routing, inject tracing provenance, terminate TLS, and prevent microservice topology exposure.")
}
