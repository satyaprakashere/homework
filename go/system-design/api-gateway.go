//go:build ignore

package main

import (
	"fmt"
	"log/slog"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	slog.Info("", "URL suffix ", r.URL.Path[1:])
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func main() {
	fmt.Println("API Gateway is running on port 8080")
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}

func handler_with_router(w http.ResponseWriter, r *http.Request) {
	router := http.NewServeMux()
	slog.Info("", "URL suffix ", r.URL.Path[1:])

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
	slog.Info("URL suffix is: ", r.URL.Path[1:], "")
	fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}
