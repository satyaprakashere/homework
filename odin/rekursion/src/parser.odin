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
	case .EOF:
		return Nil{}
	case .LEFT_PAREN:
		return parse_list(p)
	case .RIGHT_PAREN:
		// Error: unexpected )
		return Nil{}
	case .DOT:
		// Error: unexpected .
		return Nil{}
	case .QUOTE:
		expr := parse_expression(p)
		// return (quote expr)
		quote_sym := Symbol("quote")
		pair2 := new(Pair)
		pair2.first = expr
		pair2.rest = Nil{}
		pair1 := new(Pair)
		pair1.first = quote_sym
		pair1.rest = pair2
		return pair1
	case .SYMBOL:
		return Symbol(tok.text)
	case .NUMBER:
		if strings.contains(tok.text, ".") {
			f, _ := strconv.parse_f64(tok.text)
			return f
		} else {
			i, _ := strconv.parse_i64(tok.text)
			return i
		}
	case .STRING:
		// Strip quotes
		return tok.text[1:len(tok.text) - 1]
	case .BOOLEAN:
		return tok.text == "true"
	case .LEFT_BRACKET:
		// Need to check if Lexer has this
		return parse_vector(p)
	}

	return Nil{}
}

parse_list :: proc(p: ^Parser) -> Value {
	tok := parser_peek(p)
	if tok.type == .RIGHT_PAREN {
		parser_advance(p)
		return Nil{}
	}

<<<<<<< HEAD
	car := parse_expression(p)

	tok = parser_peek(p)
	if tok.type == .DOT {
		parser_advance(p) // skip .
		cdr := parse_expression(p)
		tok = parser_advance(p) // skip )
		if tok.type != .RIGHT_PAREN {
			// Error: expected ) after dotted pair
		}
		pair := new(Pair)
		pair.first = car
		pair.rest = cdr
		return pair
	}

	cdr := parse_list(p)
	pair := new(Pair)
	pair.first = car
	pair.rest = cdr
	return pair
=======
	head := new(Pair)
	curr := head

	for {
		curr.first = parse_expression(p)

		tok = parser_peek(p)
		if tok.type == .RIGHT_PAREN {
			parser_advance(p)
			curr.rest = Nil{}
			break
		}

		if tok.type == .DOT {
			parser_advance(p) // skip .
			curr.rest = parse_expression(p)
			tok = parser_advance(p) // skip )
			if tok.type != .RIGHT_PAREN {
				// Error: expected ) after dotted pair
			}
			break
		}

		if tok.type == .EOF {
			// Error: unclosed list
			curr.rest = Nil{}
			break
		}

		next := new(Pair)
		curr.rest = next
		curr = next
	}

	return head
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
}

parse_vector :: proc(p: ^Parser) -> Value {
	// Consumes [
	parser_advance(p)

	vals := make([dynamic]Value)

	for {
		tok := parser_peek(p)
		if tok.type == .RIGHT_BRACKET {
			parser_advance(p)
			break
		}
		if tok.type == .EOF {
			// Error: unexpected EOF
			break
		}

		val := parse_expression(p)
		append(&vals, val)
	}

	return Array{data = vals}
}
