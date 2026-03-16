package rekursion

Token :: struct {
	type: TokenType,
	text: string,
	line: int,
	col:  int,
}

TokenType :: enum {
	EOF,
	LEFT_PAREN,
	RIGHT_PAREN,
	DOT,
	SYMBOL,
	NUMBER,
	STRING,
	LEFT_BRACKET,
	RIGHT_BRACKET,
}
