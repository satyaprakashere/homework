package main

import (
	"math"
	"testing"
)

func TestHydrogenOrbitalDiff(t *testing.T) {
	tests := []struct {
		m, n     uint64
		expected float64
	}{
		{2, 1, 10.2043}, // 13.6057 * (1 - 1/4) = 13.6057 * 0.75 = 10.204275
		{3, 1, 12.0939}, // 13.6057 * (1 - 1/9) = 13.6057 * 0.888 = 12.09395
		{3, 2, 1.8897},  // 13.6057 * (1/4 - 1/9) = 13.6057 * 0.1388 = 1.88968
		{4, 2, 2.5511},  // 13.6057 * (1/4 - 1/16) = 13.6057 * 0.1875 = 2.55106
		{1, 1, 0.0},
	}

	const tolerance = 0.001

	h := NewHamiltonian()
	for _, tt := range tests {
		actual := h.MatrixDifference(tt.m, tt.n)
		if math.Abs(actual-tt.expected) > tolerance {
			t.Errorf("Hamiltonian.MatrixDifference(%d, %d) = %.4f; want %.4f", tt.m, tt.n, actual, tt.expected)
		}
	}
}
