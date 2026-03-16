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

parse_expression :: proc(p: ^Parser) ->  Value {// consume )
	tok := parser_advance(p)
	#partial switch tok.type {
	case .LEFT_PAREN:
		return parse_list(p)
	case .LEFT_BRACKET:
		return parse_array(p)
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
	curr := head
	for {
		curr.first = parse_expression(p)
		tok := parser_peek(p)
		if tok.type == .RIGHT_PAREN {
			parser_advance(p)
			curr.rest = Nil{}
			break
		} else if tok.type == .DOT {
			parser_advance(p)
			curr.rest = parse_expression(p)
			parser_advance(p)
			break
		} else if tok.type == .EOF {
			curr.rest = Nil{}
			break
		}
		next := new(Pair)
		curr.rest = next
		curr = next
	}
	return head
}

parse_array :: proc(p: ^Parser) -> Value {
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
