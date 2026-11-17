package main

import (
	"fmt"
	"time"
)

// Server struct uses the Functional Options pattern for configuration.
type Server struct {
	Addr    string
	Port    int
	Timeout time.Duration
}

type ServerOption func(*Server)

// WithPort sets the server port.
func WithPort(port int) ServerOption {
	return func(s *Server) { s.Port = port }
}

// WithTimeout sets the server timeout.
func WithTimeout(t time.Duration) ServerOption {
	return func(s *Server) { s.Timeout = t }
}

// NewServer creates a new server with default values and optional overrides.
func NewServer(addr string, opts ...ServerOption) *Server {
	s := &Server{
		Addr:    addr,
		Port:    8080, // Default
		Timeout: 30 * time.Second,
	}
	for _, opt := range opts {
		opt(s)
	}
	return s
}

func RunOptionsDemo() {
	fmt.Println("\n--- 2. Functional Options Demo ---")
	srv := NewServer("localhost", WithPort(9000), WithTimeout(10*time.Second))
	fmt.Printf("Server Config: %+v\n", srv)
}
