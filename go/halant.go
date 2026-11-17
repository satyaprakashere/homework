//go:build ignore
package main

import "fmt"

func main() {
    // The Latin letter "k" followed by the Unicode escape sequence for the halant
    sanskritToken := "k\u094d"

    fmt.Println(sanskritToken)
}
