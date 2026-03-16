package rekursion

Token :: struct {
	type: TokenType,
	text: string,
	line: int,
	col:  int,
}

tokens :: [TokenType]string {
	.EOF           = "EOF",
	.LEFT_PAREN    = "(",
	.RIGHT_PAREN   = ")",
	.DOT           = ".",
	.SYMBOL        = "Symbol",
	.NUMBER        = "NUMBER",
	.STRING        = "\"",
	.BOOLEAN       = "Bool",
	.LEFT_BRACKET  = "[",
	.RIGHT_BRACKET = "]",
	.LEFT_BRACE    = "{",
	.RIGHT_BRACE   = "}",
	.LAMBDA        = "lambda",
	.NEWLINE       = "\n",
	.SEMICOLON     = ";",
	.COLON         = ":",
	.COUNT         = "COUNT",
}

TokenType :: enum {
	EOF,
	LEFT_PAREN,
	RIGHT_PAREN,
	DOT,
	SYMBOL,
	NUMBER,
	STRING,
	BOOLEAN,
	LEFT_BRACKET,
	RIGHT_BRACKET,
	LEFT_BRACE,
	RIGHT_BRACE,
	LAMBDA,
	NEWLINE,
	SEMICOLON,
	COLON,
	COUNT,
}
