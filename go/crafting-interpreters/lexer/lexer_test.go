package lexer

import (
	"testing"
)

func TestNextToken(t *testing.T) {
	input := `\x:: Nat -> S(x) 0 let rec mu`

	tests := []struct {
		expectedType    TokenType
		expectedLiteral string
	}{
		{LAMBDA, "\\"},
		{IDENT, "x"},
		{DOUBLE_COLON, "::"},
		{NAT, "Nat"},
		{ARROW, "->"},
		{S_CON, "S"},
		{LPAREN, "("},
		{IDENT, "x"},
		{RPAREN, ")"},
		{NAT_LIT, "0"},
		{LET, "let"},
		{REC, "rec"},
		{MU, "mu"},
		{EOF, ""},
	}

	l := New(input)

	for i, tt := range tests {
		tok := l.NextToken()

		if tok.Type != tt.expectedType {
			t.Fatalf("tests[%d] - tokentype wrong. expected=%q, got=%q",
				i, tt.expectedType, tok.Type)
		}

		if tok.Literal != tt.expectedLiteral {
			t.Fatalf("tests[%d] - literal wrong. expected=%q, got=%q",
				i, tt.expectedLiteral, tok.Literal)
		}
	}
}

func TestArrow(t *testing.T) {
	input := `->`
	l := New(input)
	tok := l.NextToken()

	if tok.Type != ARROW {
		t.Fatalf("expected ARROW, got %s", tok.Type)
	}
}
