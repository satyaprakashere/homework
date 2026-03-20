package main

import (
	"fmt"
	"math"
)

func main() {
	var f float32 = 0.1
	// Float32bits returns the IEEE 754 binary representation
	bits := math.Float32bits(f)

	fmt.Printf("Float: %f\n", f)
	fmt.Printf("Binary: %032b\n", bits)
	fmt.Printf("Hex:    %X\n", bits)
}
