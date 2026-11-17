//go:build ignore
package main

import (
    "encoding/json"
    "fmt"
//  "io"
    "log"
    "net/http"
)

// Define a struct that matches the API response structure
type Post struct {
    ID     int    `json:"id"`
    Title  string `json:"title"`
    Body   string `json:"body"`
    UserID int    `json:"userId"`
}

func main() {
    url := "https://jsonplaceholder.typicode.com/posts/1"
    
    // 1. Make the GET request
    resp, err := http.Get(url)
    if err != nil {
        log.Fatalf("Error making GET request: %v", err)
    }
    // Always defer closing the response body to avoid memory leaks
    defer resp.Body.Close()
    
    // 2. Check the HTTP status code
    if resp.StatusCode != http.StatusOK {
        log.Fatalf("Unexpected status code: %d", resp.StatusCode)
    }
    
    // 3. Decode the JSON response into our struct
    var post Post
    if err := json.NewDecoder(resp.Body).Decode(&post); err != nil {
        log.Fatalf("Error decoding JSON: %v", err)
    }
    
    fmt.Printf("Fetched Post #%d:\nTitle: %s\n", post.ID, post.Title)
}