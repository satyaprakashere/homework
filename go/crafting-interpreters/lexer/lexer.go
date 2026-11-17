package lexer

import (
	"unicode"
)

type TokenType int

const (
	EOF TokenType = iota
	ILLEGAL

	IDENT
	NAT_LIT // 0

	// Keywords
	NAT   // Nat
	LET   // let
	IN    // in
	REC   // rec
	MU    // mu
	S_CON // S

	// Punctuations
	LAMBDA       // \
	COLON        // :
	DOT          // .
	LPAREN       // (
	RPAREN       // )
	ARROW        // ->
	DOUBLE_COLON // ::
	ASSIGN       // =
	COMMA        // ,
)

type Token struct {
	Type    TokenType
	Literal string
	Line    int
}

type Lexer struct {
	input        string
	position     int  // current position in input (points to current char)
	readPosition int  // current reading position in input (after current char)
	ch           byte // current char under examination
	line         int
}

func New(input string) *Lexer {
	l := &Lexer{input: input, line: 1}
	l.readChar()
	return l
}

func (l *Lexer) readChar() {
	if l.readPosition >= len(l.input) {
		l.ch = 0
	} else {
		l.ch = l.input[l.readPosition]
	}
	l.position = l.readPosition
	l.readPosition++
}

func (l *Lexer) peekChar() byte {
	if l.readPosition >= len(l.input) {
		return 0
	}
	return l.input[l.readPosition]
}

func (l *Lexer) NextToken() Token {
	var tok Token

	l.skipWhitespace()

	switch l.ch {
	case '\\':
		tok = l.newToken(LAMBDA, string(l.ch))
	case ':':
		if l.peekChar() == ':' {
			ch := l.ch
			l.readChar()
			tok = Token{Type: DOUBLE_COLON, Literal: string(ch) + string(l.ch), Line: l.line}
		} else {
			tok = l.newToken(COLON, string(l.ch))
		}
	case '.':
		tok = l.newToken(DOT, string(l.ch))
	case '(':
		tok = l.newToken(LPAREN, string(l.ch))
	case ')':
		tok = l.newToken(RPAREN, string(l.ch))
	case ',':
		tok = l.newToken(COMMA, string(l.ch))
	case '=':
		tok = l.newToken(ASSIGN, string(l.ch))
	case '-':
		if l.peekChar() == '>' {
			ch := l.ch
			l.readChar()
			tok = Token{Type: ARROW, Literal: string(ch) + string(l.ch), Line: l.line}
		} else if l.peekChar() == '-' {
			// Comment, skip until end of line
			l.readChar() // eat second -
			for l.ch != '\n' && l.ch != 0 {
				l.readChar()
			}
			// Recursive call to get next valid token
			return l.NextToken()
		} else {
			tok = l.newToken(ILLEGAL, string(l.ch))
		}
	case 0:
		tok.Literal = ""
		tok.Type = EOF
		tok.Line = l.line
	default:
		if isLetter(l.ch) {
			tok.Literal = l.readIdentifier()
			tok.Type = lookupIdent(tok.Literal)
			tok.Line = l.line
			return tok
		} else if isDigit(l.ch) {
			tok.Literal = l.readNumber()
			tok.Type = NAT_LIT
			tok.Line = l.line
			return tok
		} else {
			tok = l.newToken(ILLEGAL, string(l.ch))
		}
	}

	l.readChar()
	return tok
}

func (l *Lexer) newToken(tokenType TokenType, literal string) Token {
	return Token{Type: tokenType, Literal: literal, Line: l.line}
}

func (l *Lexer) readIdentifier() string {
	position := l.position
	for isLetter(l.ch) || isDigit(l.ch) {
		l.readChar()
	}
	return l.input[position:l.position]
}

func (l *Lexer) readNumber() string {
	position := l.position
	for isDigit(l.ch) {
		l.readChar()
	}
	return l.input[position:l.position]
}

func (l *Lexer) skipWhitespace() {
	for l.ch == ' ' || l.ch == '\t' || l.ch == '\n' || l.ch == '\r' {
		if l.ch == '\n' {
			l.line++
		}
		l.readChar()
	}
}

func isLetter(ch byte) bool {
	return unicode.IsLetter(rune(ch)) || ch == '_'
}

func isDigit(ch byte) bool {
	return '0' <= ch && ch <= '9'
}

var keywords = map[string]TokenType{
	"Nat": NAT,
	"let": LET,
	"in":  IN,
	"rec": REC,
	"mu":  MU,
	"S":   S_CON,
}

func lookupIdent(ident string) TokenType {
	if tok, ok := keywords[ident]; ok {
		return tok
	}
	return IDENT
}

func (t TokenType) String() string {
	switch t {
	case EOF:
		return "EOF"
	case IDENT:
		return "IDENT"
	case NAT_LIT:
		return "NAT_LIT"
	case NAT:
		return "NAT"
	case LET:
		return "LET"
	case IN:
		return "IN"
	case REC:
		return "REC"
	case MU:
		return "MU"
	case S_CON:
		return "S_CON"
	case LAMBDA:
		return "LAMBDA"
	case COLON:
		return "COLON"
	case DOT:
		return "DOT"
	case LPAREN:
		return "LPAREN"
	case RPAREN:
		return "RPAREN"
	case ARROW:
		return "ARROW"
	case DOUBLE_COLON:
		return "DOUBLE_COLON"
	case ASSIGN:
		return "ASSIGN"
	case COMMA:
		return "COMMA"
	default:
		return "UNKNOWN"
	}
}
