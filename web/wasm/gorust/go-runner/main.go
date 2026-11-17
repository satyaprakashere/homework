package main

import (
	"fmt"

	engineapi "example.com/go-runner/example/calculator/engine-api"
	"example.com/go-runner/example/calculator/types"
	"go.bytecodealliance.org/cm"
)

func main() {
	fmt.Println("🚀 [Go Runner] Initializing WASM Component...")

	// 1. Test basic operations via calculate
	ops := []struct {
		name string
		req  types.ComputeRequest
	}{
		{
			name: "Addition (128.5 + 71.5)",
			req: types.ComputeRequest{
				Op: types.OperationAdd,
				A:  128.5,
				B:  71.5,
			},
		},
		{
			name: "Multiplication (12.5 * 8.0)",
			req: types.ComputeRequest{
				Op: types.OperationMultiply,
				A:  12.5,
				B:  8.0,
			},
		},
		{
			name: "Division (100.0 / 4.0)",
			req: types.ComputeRequest{
				Op: types.OperationDivide,
				A:  100.0,
				B:  4.0,
			},
		},
		{
			name: "Division by zero (42.0 / 0.0)",
			req: types.ComputeRequest{
				Op: types.OperationDivide,
				A:  42.0,
				B:  0.0,
			},
		},
	}

	for _, tc := range ops {
		res := engineapi.Calculate(tc.req)
		if res.IsErr() {
			fmt.Printf("   %s -> Handled Error: %s\n", tc.name, *res.Err())
		} else {
			fmt.Printf("   %s -> Result: %.2f\n", tc.name, *res.OK())
		}
	}

	// 2. Test statistical analysis
	sampleData := []float64{12.4, 45.2, 78.9, 23.1, 56.7, 89.0, 34.5}
	cmList := cm.ToList(sampleData)

	statsResult := engineapi.ComputeStats(cmList)
	if statsResult.IsErr() {
		fmt.Printf("   Statistics calculation failed: %s\n", *statsResult.Err())
		return
	}

	stats := *statsResult.OK()

	// 3. Test report formatting
	report := engineapi.FormatReport("Telemetry Sample Analysis", stats)
	fmt.Println("\n" + report)
	fmt.Println("\n✅ [Go Runner] Completed communication with Engine successfully!")
}
