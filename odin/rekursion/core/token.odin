package rekursion

Token_Type :: enum {
	EOF,
	LEFT_PAREN,
	RIGHT_PAREN,
	DOT,
	QUOTE,
	SYMBOL,
	NUMBER,
	STRING,
	BOOLEAN,
	LEFT_BRACKET,
	RIGHT_BRACKET,
	LEFT_BRACE,
	RIGHT_BRACE,
	LAMBDA,
	BACKTICK,
	COMMA,
	COMMA_AT,
	NEWLINE,
	SEMICOLON,
	COLON,
}

Token :: struct {
	type: Token_Type,
	text: string,
	line: int,
	col:  int,
}
