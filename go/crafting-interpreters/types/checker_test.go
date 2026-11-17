package types

import (
	"rekursion/lexer"
	"rekursion/parser"
	"testing"
)

func TestTypeInference(t *testing.T) {
	tests := []struct {
		input        string
		expectedType string
	}{
		{"0", "Nat"},
		{"S(0)", "Nat"},
		{"\\x :: Nat -> x", "(x :: Nat) -> Nat"},
		{"(x :: Nat) -> Nat", "Nat"}, // Assuming types themselves have type Nat (Universe)
		{"let x = 0 in S(x)", "Nat"},
	}

	for _, tt := range tests {
		l := lexer.New(tt.input)
		p := parser.New(l)
		expr := p.ParseProgram()

		if len(p.Errors()) > 0 {
			t.Fatalf("parser errors for %q: %v", tt.input, p.Errors())
		}

		checker := New()
		inferred, err := checker.Infer(expr)
		if err != nil {
			t.Fatalf("type error for %q: %v", tt.input, err)
		}

		if inferred.String() != tt.expectedType {
			t.Errorf("type mismatch for %q: expected %s, got %s",
				tt.input, tt.expectedType, inferred.String())
		}
	}
}

func TestNormalisation(t *testing.T) {
	input := `(\x :: Nat -> x) 0`
	l := lexer.New(input)
	p := parser.New(l)
	expr := p.ParseProgram()

	checker := New()
	normalized := checker.Normalize(expr)

	if normalized.String() != "0" {
		t.Errorf("normalization failed: expected 0, got %s", normalized.String())
	}
}
