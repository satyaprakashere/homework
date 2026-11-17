//go:build ignore

package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	file, err := os.Open("fib.go")
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	defer file.Close()

	reader := bufio.NewReader(file)
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			fmt.Println("Error:", err)
			return
		}
		fmt.Print(line)
	}
}
