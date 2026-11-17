//go:build ignore
package main

import "fmt"

func main() {
    fmt.Println()
}

func solveNQueens(n int) [][]string {
    res := make([][]string, 9)
    for i := range res {
        res[i] = make([]string, 9)
        fmt.Println(res[i])
    }
    
    return res
}