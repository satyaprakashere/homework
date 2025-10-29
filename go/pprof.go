//go:build ignore

package main

import (
	"fmt"
	"log"
	"os"
	"runtime/pprof"
)

func main() {
	f, err := os.Create("cpu.prof")
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	if err := pprof.StartCPUProfile(f); err != nil {
		log.Fatal(err)
	}
	defer pprof.StopCPUProfile()

	// Your program logic here
	fmt.Println("hello world")
	fmt.Println(fibI(987654321))
}

func fibI(n uint64) uint64 {
	if n < 2 {
		return n
	}

	var a, b uint64 = 0, 1

	for i := 2; i <= int(n); i++ {
		a, b = b, a+b
	}
	return b
}
