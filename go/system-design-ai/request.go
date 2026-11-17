//go:build ignore

package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
)

/*
================================================================================
SYSTEM DESIGN INTERVIEW (SD3): DISTRIBUTED REQUEST LIFECYCLE & TRACING (W3C)
================================================================================
Key Topics Covered:
1. W3C TraceContext Specification:
   - Format: traceparent: 00-{trace_id}-{parent_id}-{trace_flags}
   - trace_id: 16-byte global identifier for the distributed call tree.
   - parent_id (span_id): 8-byte identifier for the specific operation hop.
   - trace_flags: 01 indicates sampled for APM (Jaeger, Zipkin, Datadog).
2. Distributed Context Propagation & Baggage:
   - Carrying tenant metadata (e.g. "tier=enterprise") across thread & network boundaries.
3. Deadline Budgeting Across Microservice Hops:
   - Passing context.Context deadlines down RPC call trees.
   - Prevents downstream services from computing work after upstream client already timed out!
================================================================================
*/

type Span struct {
	TraceID      string
	SpanID       string
	ParentSpanID string
	Operation    string
	StartTime    time.Time
	Duration     time.Duration
	Baggage      map[string]string
}

// GenerateHex generates random hex bytes for trace/span IDs
func GenerateHex(numBytes int) string {
	b := make([]byte, numBytes)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// FormatW3CTraceparent formats traceparent according to W3C TraceContext standard
func FormatW3CTraceparent(traceID, spanID string) string {
	return fmt.Sprintf("00-%s-%s-01", traceID, spanID)
}

// ParseW3CTraceparent parses a W3C traceparent header
func ParseW3CTraceparent(header string) (traceID, parentID string, err error) {
	parts := strings.Split(header, "-")
	if len(parts) != 4 || parts[0] != "00" {
		return "", "", fmt.Errorf("invalid W3C traceparent: %s", header)
	}
	return parts[1], parts[2], nil
}

// Tracer simulates an OpenTelemetry tracer with context propagation
type Tracer struct{}

func (t *Tracer) StartSpan(ctx context.Context, opName string) (context.Context, *Span) {
	traceID, _ := ctx.Value("trace_id").(string)
	parentSpanID, _ := ctx.Value("span_id").(string)
	baggage, _ := ctx.Value("baggage").(map[string]string)

	if traceID == "" {
		traceID = GenerateHex(16) // 32 hex chars
	}
	currentSpanID := GenerateHex(8) // 16 hex chars

	if baggage == nil {
		baggage = make(map[string]string)
	}

	span := &Span{
		TraceID:      traceID,
		SpanID:       currentSpanID,
		ParentSpanID: parentSpanID,
		Operation:    opName,
		StartTime:    time.Now(),
		Baggage:      baggage,
	}

	// Propagate in Go context
	newCtx := context.WithValue(ctx, "trace_id", traceID)
	newCtx = context.WithValue(newCtx, "span_id", currentSpanID)
	newCtx = context.WithValue(newCtx, "baggage", baggage)

	return newCtx, span
}

func (t *Tracer) FinishSpan(span *Span) {
	span.Duration = time.Since(span.StartTime)
	fmt.Printf("  [SPAN FINISHED] Op: %-20s | TraceID: %s | SpanID: %s | Parent: %-16s | Latency: %v\n",
		span.Operation, span.TraceID[:8]+"...", span.SpanID, span.ParentSpanID, span.Duration)
}

// -----------------------------------------------------------------------------
// MICROSERVICE CALL CHAIN SIMULATION
// -----------------------------------------------------------------------------

var globalTracer = &Tracer{}

// Hop 1: API Gateway
func APIGatewayService(ctx context.Context) {
	ctx, span := globalTracer.StartSpan(ctx, "api-gateway.ingress")
	defer globalTracer.FinishSpan(span)

	// Attach Baggage (e.g. Tenant ID)
	span.Baggage["tenant_id"] = "corp-vip-441"

	time.Sleep(10 * time.Millisecond)

	// Call Order Service (Hop 2)
	OrderService(ctx)
}

// Hop 2: Order Service
func OrderService(ctx context.Context) {
	ctx, span := globalTracer.StartSpan(ctx, "order-service.create")
	defer globalTracer.FinishSpan(span)

	time.Sleep(15 * time.Millisecond)

	// Call Payment Service (Hop 3)
	PaymentService(ctx)
}

// Hop 3: Payment Service (Leaf)
func PaymentService(ctx context.Context) {
	_, span := globalTracer.StartSpan(ctx, "payment-service.charge")
	defer globalTracer.FinishSpan(span)

	time.Sleep(20 * time.Millisecond)
	fmt.Printf("  -> Payment processed for Tenant Baggage: %s\n", span.Baggage["tenant_id"])
}

func main() {
	fmt.Println("=== SD3 Distributed Request Lifecycle: OpenTelemetry & W3C TraceContext ===")

	// 1. W3C Header Format
	fmt.Println("\n[1] Generating W3C TraceContext 'traceparent' Header:")
	traceID := GenerateHex(16)
	spanID := GenerateHex(8)
	header := FormatW3CTraceparent(traceID, spanID)
	fmt.Printf("  traceparent: %s\n", header)

	pTraceID, pSpanID, _ := ParseW3CTraceparent(header)
	fmt.Printf("  Parsed -> TraceID: %s | ParentSpanID: %s\n", pTraceID, pSpanID)

	// 2. Multi-Hop Distributed Trace Execution (Gateway -> Order -> Payment)
	fmt.Println("\n[2] Executing 3-Hop Distributed Trace Call Tree:")
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	APIGatewayService(ctx)

	fmt.Println("\n[SD3 Takeaway]: W3C TraceContext ties all asynchronous & distributed hops into a single DAG; Baggage propagates tenant context across networks.")
}
