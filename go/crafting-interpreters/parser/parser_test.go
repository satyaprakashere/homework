package parser

import (
	"rekursion/lexer"
	"testing"
)

func TestParseExpression(t *testing.T) {
	input := `\x :: Nat -> S(x)`
	l := lexer.New(input)
	p := New(l)
	expr := p.ParseProgram()

	if len(p.Errors()) != 0 {
		t.Errorf("parser has %d errors", len(p.Errors()))
		for _, msg := range p.Errors() {
			t.Errorf("parser error: %q", msg)
		}
		t.FailNow()
	}

	if expr == nil {
		t.Fatalf("ParseProgram() returned nil")
	}

	expected := `\x :: Nat -> S(x)`
	if expr.String() != expected {
		t.Errorf("expected %q, got %q", expected, expr.String())
	}
}

func TestParseRec(t *testing.T) {
	input := `rec(0, 0, \n :: Nat -> \p :: Nat -> S(p))`
	l := lexer.New(input)
	p := New(l)
	expr := p.ParseProgram()

	if len(p.Errors()) != 0 {
		t.Fatalf("parser errors: %v", p.Errors())
	}

	expected := `rec(0, 0, \n :: Nat -> \p :: Nat -> S(p))`
	if expr.String() != expected {
		t.Errorf("expected %q, got %q", expected, expr.String())
	}
}

func TestParsePi(t *testing.T) {
	input := `(x :: Nat) -> Nat`
	l := lexer.New(input)
	p := New(l)
	expr := p.ParseProgram()

	if len(p.Errors()) != 0 {
		t.Fatalf("parser errors: %v", p.Errors())
	}

	expected := `(x :: Nat) -> Nat`
	if expr.String() != expected {
		t.Errorf("expected %q, got %q", expected, expr.String())
	}
}
