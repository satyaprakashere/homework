//go:build ignore

package main

import (
	"context"
	"log"
	"net"

	pb "path/to/your/generated/proto"

	"google.golang.org/grpc"
)

// server is used to implement the Inventory service
type server struct {
	pb.UnimplementedInventoryServer
}

// GetBookInfo implements the RPC method defined in the .proto file
func (s *server) GetBookInfo(ctx context.Context, in *pb.BookRequest) (*pb.BookResponse, error) {
	log.Printf("Received request for ISBN: %v", in.GetIsbn())

	// In a real app, you'd fetch this from a database
	return &pb.BookResponse{
		Title:         "The Go Programming Language",
		Author:        "Alan A. A. Donovan",
		YearPublished: 2015,
	}, nil
}

func main() {
	lis, _ := net.Listen("tcp", ":50051")
	s := grpc.NewServer()
	pb.RegisterInventoryServer(s, &server{})
	log.Println("Server listening on :50051")
	s.Serve(lis)
}
