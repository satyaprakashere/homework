package rekursion

import "core:unicode"
import "core:unicode/utf8"

Lexer :: struct {
	source: string,
	offset: int,
	line:   int,
	col:    int,
}

lexer_init :: proc(source: string) -> Lexer {
	return Lexer{source = source, line = 1, col = 1}
}

lexer_next_token :: proc(l: ^Lexer) -> Token {
	lexer_skip_whitespace(l)

	if l.offset >= len(l.source) {
		return Token{type = .EOF, text = "", line = l.line, col = l.col}
	}

	r, size := utf8.decode_rune_in_string(l.source[l.offset:])
	start_offset := l.offset
	start_line := l.line
	start_col := l.col

	switch r {
	case '(':
		return lexer_emit(l, .LEFT_PAREN, "(", size)
	case ')':
		return lexer_emit(l, .RIGHT_PAREN, ")", size)
	case '[':
		return lexer_emit(l, .LEFT_BRACKET, "[", size)
	case ']':
		return lexer_emit(l, .RIGHT_BRACKET, "]", size)
	case '.':
		return lexer_emit(l, .DOT, ".", size)
	case '"':
		return lexer_read_string(l)
	}

	if unicode.is_digit(r) ||
	   (r == '-' &&
			   l.offset + 1 < len(l.source) &&
			   unicode.is_digit(rune(l.source[l.offset + 1]))) {
		return lexer_read_while(l, .NUMBER, proc(r: rune) -> bool {
			return unicode.is_digit(r) || r == '.'
		})
	}

	if is_symbol_char(r) {
		return lexer_read_while(l, .SYMBOL, is_symbol_char)
	}

	l.offset += size
	l.col += 1
	return Token{type = .EOF, text = "ERROR", line = start_line, col = start_col}
}

lexer_emit :: proc(l: ^Lexer, type: TokenType, text: string, size: int) -> Token {
	tok := Token {
		type = type,
		text = text,
		line = l.line,
		col  = l.col,
	}
	l.offset += size
	l.col += 1
	return tok
}

lexer_read_while :: proc(l: ^Lexer, type: TokenType, predicate: proc(_: rune) -> bool) -> Token {
	start := l.offset
	start_line, start_col := l.line, l.col
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		if predicate(r) {
			l.offset += size
			l.col += 1
		} else {
			break
		}
	}
	return Token{type = type, text = l.source[start:l.offset], line = start_line, col = start_col}
}

lexer_read_string :: proc(l: ^Lexer) -> Token {
	start, start_line, start_col := l.offset, l.line, l.col
	l.offset += 1; l.col += 1 // skip "
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		l.offset += size
		l.col += 1
		if r == '"' {break}
	}
	return Token {
		type = .STRING,
		text = l.source[start:l.offset],
		line = start_line,
		col = start_col,
	}
}

lexer_skip_whitespace :: proc(l: ^Lexer) {
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		
		if unicode.is_white_space(r) {
			lexer_advance_line_col(l, r)
			l.offset += size
			continue
		}

		if r == ';' {
			lexer_skip_comment(l)
			continue
		}

		break
	}
}

lexer_advance_line_col :: proc(l: ^Lexer, r: rune) {
	if r == '\n' {
		l.line += 1
		l.col = 1
		return
	}
	l.col += 1
}

lexer_skip_comment :: proc(l: ^Lexer) {
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		l.offset += size
		if r == '\n' {
			l.line += 1
			l.col = 1
			break
		}
	}
}
