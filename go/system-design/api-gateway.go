//go:build ignore
package main

<<<<<<< Updated upstream
import (
    "fmt"
    "net/http")

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hi there, I love %s!", r.URL.Path[1:])
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":8080", nil)
}
=======
import "fmt"

func main() {
    fmt.Println("Hello from API Gateway")
}

func send_req() {
    
}
>>>>>>> Stashed changes
