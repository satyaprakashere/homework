//go:build ignore

package main

import "fmt"

func Ackermann(m, n uint) uint {
	if m == 0 { return n + 1 }
	if n == 0 { return Ackermann(m-1, 1) }

	return Ackermann(m-1, Ackermann(m, n-1))
}

func main() {
	tests := []test{
		{0, 0, 1},
		{0, 1, 2},
		{1, 0, 2},
		{1, 1, 3},
		{2, 2, 7},
		{3, 2, 29},
		{3, 3, 61},
		{3, 4, 125},
		{4, 0, 13},
		// {4, 1, 65533},
	}

	for _, tt := range tests {
		got := Ackermann(tt.m, tt.n)
		if got != tt.want {
			_ = fmt.Errorf("Ackermann(%d, %d) = %d; expected %d", tt.m, tt.n, got, tt.want)
		}
		fmt.Printf("Ackermann(%d, %d) = %d\n", tt.m, tt.n, got)
	}
}

type test struct {
	m, n uint
	want uint
}
