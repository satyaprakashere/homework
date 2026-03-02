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

parse_expression :: proc(p: ^Parser) -> Value {
	tok := parser_advance(p)
	#partial switch tok.type {
	case .EOF, .RIGHT_PAREN, .RIGHT_BRACKET, .DOT:
		return Nil{}
	case .LEFT_PAREN:
		return parse_list(p)
	case .QUOTE:
		return parse_quote_expr(p, "quote")
	case .BACKTICK:
		return parse_quote_expr(p, "quasiquote")
	case .COMMA:
		return parse_quote_expr(p, "unquote")
	case .COMMA_AT:
		return parse_quote_expr(p, "unquote-splicing")
	case .SYMBOL:
		return Symbol(tok.text)
	case .NUMBER:
		return parse_number_value(tok.text)
	case .STRING:
		return tok.text[1:len(tok.text) - 1]
	case .BOOLEAN:
		return tok.text == "true" || tok.text == "false"
	case .LEFT_BRACKET:
		return parse_vector(p)
	}
	return Nil{}
}

parse_quote_expr :: proc(p: ^Parser, quote_type: string) -> Value {
	expr := parse_expression(p)
	quote_sym := Symbol(quote_type)

	pair1, pair2 := new(Pair), new(Pair)
	pair2.first, pair2.rest = expr, Nil{}
	pair1.first, pair1.rest = quote_sym, pair2

	return pair1
}

parse_number_value :: proc(text: string) -> Value {
	if strings.contains(text, ".") {
		f, _ := strconv.parse_f64(text)
		return f
	}
	i, _ := strconv.parse_i64(text)
	return i
}

parse_list :: proc(p: ^Parser) -> Value {
	if parser_peek(p).type == .RIGHT_PAREN {
		parser_advance(p)
		return Nil{}
	}
	head := new(Pair)
	parse_list_elements(p, head)
	return head
}

parse_list_elements :: proc(p: ^Parser, head: ^Pair) {
	curr := head
	for {
		curr.first = parse_expression(p)
		next, done := parse_list_next(p, curr)
		if done {break}
		curr = next
	}
}

parse_list_next :: proc(p: ^Parser, curr: ^Pair) -> (^Pair, bool) {
	tok := parser_peek(p)
	if tok.type == .RIGHT_PAREN {parser_advance(p); curr.rest = Nil{}; return nil, true}
	if tok.type == .DOT {
		parser_advance(p); curr.rest = parse_expression(p); parser_advance(p); return nil, true
	}
	if tok.type == .EOF {curr.rest = Nil{}; return nil, true}
	next := new(Pair)
	curr.rest = next
	return next, false
}

parse_vector :: proc(p: ^Parser) -> Value {
	parser_advance(p)
	vals := make([dynamic]Value)
	for {
		tok := parser_peek(p)
		if tok.type == .RIGHT_BRACKET || tok.type == .EOF {
			if tok.type == .RIGHT_BRACKET {parser_advance(p)}
			break
		}
		append(&vals, parse_expression(p))
	}
	return Array{data = vals}
}
