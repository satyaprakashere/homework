//go:build ignore

package main

import (
	"context"
	"log"
	"time"

	pb "path/to/your/generated/proto"

	"google.golang.org/grpc"
)

func main() {
	// Set up a connection to the server
	conn, _ := grpc.Dial("localhost:50051", grpc.WithInsecure())
	defer conn.Close()
	c := pb.NewInventoryClient(conn)

	// Contact the server and print out its response
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	r, err := c.GetBookInfo(ctx, &pb.BookRequest{Isbn: "978-0134190440"})
	if err != nil {
		log.Fatalf("Could not get book: %v", err)
	}
	log.Printf("Book Title: %s by %s", r.GetTitle(), r.GetAuthor())
}
