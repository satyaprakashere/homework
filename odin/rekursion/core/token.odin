package rekursion


Token :: struct {
	type: TokenType,
	text: string,
	line: int,
	col:  int,
}

tokens := [TokenType.COUNT]string {
	"EOF",
	"(",
	")",
	".",
	"\"",
	"Symbol",
	"NUMBER",
	"Srting",
	"Bool",
	"[",
	"]",
	"{",
	"}",
	"lambda",
	"`",
	",",
	",",
	"\n",
	";",
	":",
}

TokenType :: enum {
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

	COUNT,
}
