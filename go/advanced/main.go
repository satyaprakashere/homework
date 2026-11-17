package main

import "fmt"

func main() {
	fmt.Println("=== Advanced Go Learning Lab ===")

	// 1. Generics
	RunGenericsDemo()

	// 2. Functional Options
	RunOptionsDemo()

	// 3. Worker Pool with Context
	RunWorkerPoolDemo()

	// 4. Middleware
	RunMiddlewareDemo()

	// 5. Dependency Injection
	RunDIDemo()

	// 6. Atomic Operations
	RunAtomicDemo()

	// 7. Custom Error Types
	RunErrorDemo()

	fmt.Println("\n=== Learning Lab Complete ===")
}
