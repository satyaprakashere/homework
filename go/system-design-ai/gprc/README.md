# gRPC & Protocol Buffers Deep Dive for SD3

This directory contains examples and documentation for building high-performance microservices using **gRPC** and **Protocol Buffers (protobuf)**.

---

## 1. Why gRPC for Internal Microservices? (SD3 Architecture)

| Dimension | REST (JSON over HTTP/1.1) | gRPC (Protobuf over HTTP/2) |
| :--- | :--- | :--- |
| **Serialization** | Text-based JSON (slow parsing, verbose keys) | Binary Protobuf (up to 10x faster, compact wire size) |
| **Transport** | HTTP/1.1 (TCP head-of-line blocking) | HTTP/2 (Multiplexed streams over 1 TCP connection) |
| **API Contract** | Loose OpenAPI / Swagger (runtime errors) | Strict, backwards-compatible `.proto` schema IDL |
| **Streaming** | Difficult (WebSockets or SSE required) | Native (Unary, Server, Client, Bidirectional streaming) |
| **Code Generation** | Third-party generators | Built-in via `protoc` for 10+ languages |

---

## 2. Protobuf Compilation Workflow

To generate Go code from `library.proto`:

```bash
# 1. Install protocol buffer compiler and Go plugins:
brew install protobuf
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# 2. Compile .proto file:
protoc --go_out=. --go_opt=paths=source_relative \
       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
       library.proto
```

---

## 3. Four RPC Communication Patterns

1. **Unary RPC**: Standard Request-Response (Client sends 1 message, Server replies with 1 message).
2. **Server Streaming RPC**: Client sends 1 request, Server returns a stream of responses (e.g. live stock ticker, log tailing).
3. **Client Streaming RPC**: Client streams chunks of data, Server returns 1 composite status (e.g. large file upload, telemetry ingestion).
4. **Bidirectional Streaming RPC**: Both Client and Server read and write to independent streams simultaneously (e.g. live chat, gaming state sync).

---

## 4. Key SD3 Interview Talking Points

- **Protobuf Backward Compatibility Rules**:
  - NEVER change field numbers (`isbn = 1;`). Field tags define wire identity!
  - You can rename field names freely without breaking wire compatibility.
  - Deprecate old fields using the `reserved` keyword so future developers don't reuse the tag number.
- **Load Balancing gRPC**:
  - Standard L4 load balancers DO NOT WORK with gRPC! Because HTTP/2 multiplexes all requests over a single TCP connection, an L4 proxy forwards all requests to the same single backend server.
  - Solution: Layer 7 load balancer (Envoy / AWS ALB) or Client-Side Load Balancing with DNS / Consul.
