//go:build ignore

package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	for {
		fmt.Println("info: gFib(10, 20) = ", gFib(10, 20))
		
		reader := bufio.NewReader(os.Stdin)
		input, _ := reader.ReadString('\n')
		
		// Trim whitespace and newline characters
		trimmedInput := strings.TrimSpace(input)

		if trimmedInput != "y" {
			fmt.Println(input)
			return
		}
	}
}

func gFib(n uint64, m uint64) uint64 {
	if n == m {
		return 0
	}
	
	if n == 0 {
		
	}
	return 0
}
