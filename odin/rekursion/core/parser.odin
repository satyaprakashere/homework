package rekursion

import "core:strconv"
import "core:strings"

Parser :: struct {
	lexer:      Lexer,
	peeked:     Token,
	has_peeked: bool,
}

parser_init :: proc(source: string) -> Parser {
	return Parser{lexer = lexer_init(source)}
}

parser_peek :: proc(p: ^Parser) -> Token {
	if !p.has_peeked {
		p.peeked = lexer_next_token(&p.lexer)
		p.has_peeked = true
	}
	return p.peeked
}

parser_advance :: proc(p: ^Parser) -> Token {
	if p.has_peeked {
		p.has_peeked = false
		return p.peeked
	}
	return lexer_next_token(&p.lexer)
}

parse_expression :: proc(p: ^Parser, allocator := context.allocator) -> Value {
	tok := parser_advance(p)
	#partial switch tok.type {
	case .LEFT_PAREN:
		return parse_list(p, allocator)
	case .LEFT_BRACKET:
		return parse_array(p, allocator)
	case .SYMBOL:
		return Symbol(tok.text)
	case .NUMBER:
		return parse_number_value(tok.text)
	case .STRING:
		return tok.text[1:len(tok.text) - 1]
	case:
		return Nil{}
	}
}

parse_number_value :: proc(text: string) -> Value {
	if i_val, i_ok := strconv.parse_i64(text); i_ok {
		return i_val
	}
	if f_val, f_ok := strconv.parse_f64(text); f_ok {
		return f_val
	}
	// Fallback to symbol if it matches NUMBER pattern but fails to parse (e.g. out of range)
	return Symbol(text)
}

parse_list :: proc(p: ^Parser, allocator := context.allocator) -> Value {
	if parser_peek(p).type == .RIGHT_PAREN {
		parser_advance(p)
		return Nil{}
	}

	head := new(Pair, allocator)
	curr := head
	for {
		curr.first = parse_expression(p, allocator)
		tok := parser_peek(p)
		if tok.type == .RIGHT_PAREN {
			parser_advance(p)
			curr.rest = Nil{}
			break
		} else if tok.type == .DOT {
			parser_advance(p)
			curr.rest = parse_expression(p, allocator)
			parser_advance(p)
			break
		} else if tok.type == .EOF {
			curr.rest = Nil{}
			break
		}
		next := new(Pair, allocator)
		curr.rest = next
		curr = next
	}
	return head
}

parse_array :: proc(p: ^Parser, allocator := context.allocator) -> Value {
	vals := make([dynamic]Value, allocator)
	for {
		tok := parser_peek(p)
		if tok.type == .RIGHT_BRACKET || tok.type == .EOF {
			if tok.type == .RIGHT_BRACKET {parser_advance(p)}
			break
		}
		append(&vals, parse_expression(p, allocator))
	}
	return Array{data = vals}
}
