package main

import (
	"fmt"
	"strings"
)

// Handler represents a simple function that processes a string.
type Handler func(string)

// LoggerMiddleware logs before and after the next handler.
func LoggerMiddleware(next Handler) Handler {
	return func(data string) {
		fmt.Printf("[LOG] Entering: %s\n", data)
		next(data)
		fmt.Printf("[LOG] Exiting: %s\n", data)
	}
}

// UpperCaseMiddleware transforms the input to uppercase.
func UpperCaseMiddleware(next Handler) Handler {
	return func(data string) {
		next(strings.ToUpper(data))
	}
}

func finalHandler(data string) {
	fmt.Printf("Final Handler Output: %s\n", data)
}

func RunMiddlewareDemo() {
	fmt.Println("\n--- 4. Middleware Pattern Demo ---")
	// Chain: Logger -> UpperCase -> Final
	chain := LoggerMiddleware(UpperCaseMiddleware(finalHandler))
	chain("hello world")
}
