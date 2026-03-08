package rekursion

import "core:strings"
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

is_whitespace :: proc(r: rune) -> bool {
	return unicode.is_white_space(r)
}

is_digit :: proc(r: rune) -> bool {
	return unicode.is_digit(r)
}

is_symbol_char :: proc(r: rune) -> bool {
	if unicode.is_letter(r) || unicode.is_digit(r) {return true}
	return strings.contains_rune("+-*/<=>?!_$", r)
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
		l.offset += 1
		l.col += 1
		return Token{type = .LEFT_PAREN, text = "(", line = start_line, col = start_col}
	case ')':
		l.offset += 1
		l.col += 1
		return Token{type = .RIGHT_PAREN, text = ")", line = start_line, col = start_col}
	case '\'':
		l.offset += 1
		l.col += 1
		return Token{type = .QUOTE, text = "'", line = start_line, col = start_col}
	case '`':
		l.offset += 1
		l.col += 1
		return Token{type = .BACKTICK, text = "`", line = start_line, col = start_col}
	case ',':
		l.offset += 1
		l.col += 1
		r_next, _ := utf8.decode_rune_in_string(l.source[l.offset:])
		if r_next == '@' {
			l.offset += 1
			l.col += 1
			return Token{type = .COMMA_AT, text = ",@", line = start_line, col = start_col}
		}
		return Token{type = .COMMA, text = ",", line = start_line, col = start_col}
	case '.':
		l.offset += 1
		l.col += 1
		return Token{type = .DOT, text = ".", line = start_line, col = start_col}
	// case '#':
	// 	return lexer_read_hash(l, start_offset, start_line, start_col)
	case '"':
		return lexer_read_string(l)
	case '[':
		l.offset += 1
		l.col += 1
		return Token{type = .LEFT_BRACKET, text = "[", line = start_line, col = start_col}
	case ']':
		l.offset += 1
		l.col += 1
		return Token{type = .RIGHT_BRACKET, text = "]", line = start_line, col = start_col}
	}

	if is_digit(r) ||
	   (r == '-' && l.offset + 1 < len(l.source) && is_digit(rune(l.source[l.offset + 1]))) {
		return lexer_read_number(l)
	}

	if is_symbol_char(r) {
		return lexer_read_symbol(l)
	}

	// Unknown char
	l.offset += size
	l.col += 1
	return Token{type = .EOF, text = "ERROR", line = start_line, col = start_col}
}

// lexer_read_hash :: proc(l: ^Lexer, start_offset, start_line, start_col: int) -> Token {
// 	l.offset += 1
// 	l.col += 1
// 	r_next, size_next := utf8.decode_rune_in_string(l.source[l.offset:])
// 	if r_next == 't' || r_next == 'f' {
// 		l.offset += size_next
// 		l.col += 1
// 		return Token {
// 			type = .BOOLEAN,
// 			text = l.source[start_offset:l.offset],
// 			line = start_line,
// 			col = start_col,
// 		}
// 	}
// 	// Fallthrough error
// 	return Token{type = .EOF, text = "ERROR", line = start_line, col = start_col}
// }

lexer_skip_whitespace :: proc(l: ^Lexer) {
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		if is_whitespace(r) {
			if r == '\n' {
				l.line += 1
				l.col = 1
			} else {
				l.col += 1
			}
			l.offset += size
		} else if r == ';' {
			lexer_skip_comment(l)
		} else {
			break
		}
	}
}

lexer_skip_comment :: proc(l: ^Lexer) {
	for l.offset < len(l.source) {
		r_next, size_next := utf8.decode_rune_in_string(l.source[l.offset:])
		l.offset += size_next
		if r_next == '\n' {
			l.line += 1
			l.col = 1
			break
		}
	}
}

lexer_read_number :: proc(l: ^Lexer) -> Token {
	start := l.offset
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		if is_digit(r) || r == '.' {
			l.offset += size
			l.col += 1
		} else {
			break
		}
	}
	return Token {
		type = .NUMBER,
		text = l.source[start:l.offset],
		line = l.line,
		col = l.col - (l.offset - start),
	}
}

lexer_read_symbol :: proc(l: ^Lexer) -> Token {
	start := l.offset
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		if is_symbol_char(r) {
			l.offset += size
			l.col += 1
		} else {
			break
		}
	}
	return Token {
		type = .SYMBOL,
		text = l.source[start:l.offset],
		line = l.line,
		col = l.col - (l.offset - start),
	}
}

lexer_read_string :: proc(l: ^Lexer) -> Token {
	start_offset := l.offset
	l.offset += 1 // skip "
	l.col += 1
	for l.offset < len(l.source) {
		r, size := utf8.decode_rune_in_string(l.source[l.offset:])
		l.offset += size
		l.col += 1
		if r == '"' {
			break
		}
	}
	return Token {
		type = .STRING,
		text = l.source[start_offset:l.offset],
		line = l.line,
		col = l.col - (l.offset - start_offset),
	}
}
