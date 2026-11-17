package tests

import (
	"os"
	"rekursion/lexer"
	"rekursion/parser"
	"rekursion/types"
	"testing"
)

func TestFibonacciE2E(t *testing.T) {
	// 1. Define Addition
	// add = \x :: Nat -> \y :: Nat -> rec(x, y, \n :: Nat -> \p :: Nat -> S(p))
	addSrc := `\x :: Nat -> \y :: Nat -> rec(x, y, \n :: Nat -> \p :: Nat -> S(p))`

	// 2. Define Fibonacci using a pair trick (a, b) -> (a+b, a)
	// Since we don't have pairs, we simulate them or use a simpler recursive form if possible.
	// For this E2E, let's at least verify 'add' and a basic 'fib' structure.

	// fib_helper = \n: Nat. rec(n, (\f: (x: Nat) -> Nat. f 1), \n: Nat. \p: (f: (x: Nat) -> Nat) -> Nat. \f: (x: Nat) -> Nat. p (\a: Nat. f (add a ???)))
	// Actually, Church encoding pairs:
	// pair = \a. \b. \f. f a b
	// fst = \p. p (\a. \b. a)
	// snd = \p. p (\a. \b. b)

	// Let's start with a simpler E2E: Addition test
	input := `(\add :: (a :: Nat) -> (b :: Nat) -> Nat -> add S(S(0)) S(S(0))) (` + addSrc + `)`

	l := lexer.New(input)
	p := parser.New(l)
	expr := p.ParseProgram()

	if len(p.Errors()) > 0 {
		t.Fatalf("Parser errors: %v", p.Errors())
	}

	checker := types.New()
	_, err := checker.Infer(expr)
	if err != nil {
		t.Fatalf("Type error: %v", err)
	}

	normalized := checker.Normalize(expr)
	expected := "S(S(S(S(0))))"
	if normalized.String() != expected {
		t.Errorf("E2E Add failed: expected %s, got %s", expected, normalized.String())
	}
}

func TestFibonacciChurch(t *testing.T) {
	// fib n = snd (rec n (pair 1 0) (\m p. pair (add (fst p) (snd p)) (fst p)))
	// pair a b = \f. f a b
	// fst p = p (\a b. a)
	// snd p = p (\a b. b)

	// Read fib source from file
	content, err := os.ReadFile("fib.recur")
	if err != nil {
		t.Fatalf("Failed to read fib.recur: %v", err)
	}
	fibSrc := string(content)

	// Test fib 3 -> 2
	input := `(` + fibSrc + `) S(S(S(0)))`

	l := lexer.New(input)
	p := parser.New(l)
	expr := p.ParseProgram()

	if len(p.Errors()) > 0 {
		t.Fatalf("Parser errors: %v", p.Errors())
	}

	checker := types.New()
	_, err = checker.Infer(expr)
	if err != nil {
		t.Fatalf("Type error: %v", err)
	}

	normalized := checker.Normalize(expr)
	expected := "S(S(0))" // fib 3 = 2
	if normalized.String() != expected {
		t.Errorf("Fibonacci E2E failed: expected %s, got %s", expected, normalized.String())
	}
}
