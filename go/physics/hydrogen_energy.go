// Package main provides a utility to calculate energy transitions in a hydrogen atom.
package main

import (
	"fmt"
	"math"
	"os"
	"strconv"
)

// Hamiltonian represents the energy operator in the energy eigenbasis.
// In Heisenberg's matrix mechanics, the Hamiltonian is a diagonal matrix.
type Hamiltonian struct {
	RydbergEnergy float64
}

// NewHamiltonian initializes a Hamiltonian for the Hydrogen atom.
func NewHamiltonian() *Hamiltonian {
	return &Hamiltonian{
		RydbergEnergy: 13.605693,
	}
}

// GetEigenvalue returns the diagonal matrix element H_nn for the given state n.
// Formula: H_nn = -E_R / n^2
func (h *Hamiltonian) GetEigenvalue(n uint64) float64 {
	if n == 0 {
		return 0
	}
	return -h.RydbergEnergy / float64(n*n)
}

// MatrixDifference calculates the transition energy between two states (orbitals).
// This corresponds to the difference between the diagonal entries H_mm and H_nn.
func (h *Hamiltonian) MatrixDifference(m, n uint64) float64 {
	return math.Abs(h.GetEigenvalue(m) - h.GetEigenvalue(n))
}

func main() {
	h := NewHamiltonian()

	if len(os.Args) < 3 {
		fmt.Println("Usage: hydrogen_energy <m> <n>")
		fmt.Println("Based on Heisenberg's Matrix Formulation")

		// Default evaluation for n=2 to n=1 transition
		m, n := uint64(2), uint64(1)
		diff := h.MatrixDifference(m, n)
		fmt.Printf("Matrix transition energy between indices m=%d and n=%d: %.4f eV\n", m, n, diff)
		return
	}

	m, errM := strconv.ParseUint(os.Args[1], 10, 64)
	n, errN := strconv.ParseUint(os.Args[2], 10, 64)

	if errM != nil || errN != nil {
		fmt.Println("Error: parameters m and n must be positive integers.")
		os.Exit(1)
	}

	diff := h.MatrixDifference(m, n)
	fmt.Printf("Matrix transition energy between indices m=%d and n=%d: %.4f eV\n", m, n, diff)
}
