//go:build ignore

package main

import (
	"fmt"
	"io"
	"log/slog"
	"math/rand"
	"net/http"
	"sync"
	"time"
)

func main() {
	fmt.Println("API Gateway is running on port 8080")
	choice := 1

	switch choice {
	case 3:
		http.HandleFunc("/", handler_with_rate_limiter)
	case 2:
		http.HandleFunc("/", handler_with_router)
	default:
		http.HandleFunc("/", handler)
	}

	wg := sync.WaitGroup{}

	wg.Go(func() { http.ListenAndServe(":8080", nil) })
	time.Sleep(100 * time.Millisecond)
	fmt.Println("Server has started....")

	for range 10000 {
		id := rand.Intn(10000)
		time.Sleep(time.Duration(id) * time.Microsecond)
		wg.Go(func() { random_client(id) })
	}

	wg.Wait()
}

func handler(w http.ResponseWriter, r *http.Request) {
	slog.Info("", "URL suffix", r.URL.Path[0:])
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func random_client(id int) {
	resp, err := http.Get(fmt.Sprintf("http://localhost:8080/products/%d", id))
	if err != nil {
		slog.Error("Failed to make request: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		slog.Error("Failed to read response body: %v", err)
	}

	fmt.Println(string(body))
}

func handler_with_router(w http.ResponseWriter, r *http.Request) {
	router := http.NewServeMux()
	slog.Info("", "URL suffix", r.URL.Path[1:])

	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
	})
	router.HandleFunc("/users", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hi a User there, I love %s!", r.URL.Path[1:])
	})
	router.HandleFunc("/products", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hi a Product there, I love %s!", r.URL.Path[1:])
	})
	router.HandleFunc("/orders", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hi a Order there, I love %s!", r.URL.Path[1:])
	})

	router.ServeHTTP(w, r)
}

func handler_with_rate_limiter(w http.ResponseWriter, r *http.Request) {
	// rate_limiter :=
	slog.Info("URL suffix is:", r.URL.Path[1:], "")
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}
