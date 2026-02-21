package parser

import (
	"fmt"
	"rekursion/ast"
	"rekursion/lexer"
)

type Parser struct {
	l         *lexer.Lexer
	curToken  lexer.Token
	peekToken lexer.Token
	errors    []string
}

func New(l *lexer.Lexer) *Parser {
	p := &Parser{l: l}
	// Read two tokens, so curToken and peekToken are both set
	p.nextToken()
	p.nextToken()
	return p
}

func (p *Parser) nextToken() {
	p.curToken = p.peekToken
	p.peekToken = p.l.NextToken()
}

func (p *Parser) Errors() []string {
	return p.errors
}

func (p *Parser) ParseProgram() ast.Expr {
	return p.parseExpression()
}

func (p *Parser) parseExpression() ast.Expr {
	fmt.Printf("DEBUG: parseExpression cur=%s\n", p.curToken.Type)
	// fmt.Printf("DEBUG: parseExpression cur=%s\n", p.curToken.Type)
	if p.curToken.Type == lexer.LAMBDA {
		return p.parseLambda()
	}
	if p.curToken.Type == lexer.LET {
		return p.parseLet()
	}
	return p.parseApplication()
}

func (p *Parser) parseLambda() ast.Expr {
	p.nextToken() // skip \
	if p.curToken.Type != lexer.IDENT {
		p.errors = append(p.errors, fmt.Sprintf("expected identifier after \\, got %s", p.curToken.Literal))
		return nil
	}
	name := p.curToken.Literal
	p.nextToken() // skip ident

	if p.curToken.Type != lexer.DOUBLE_COLON {
		p.errors = append(p.errors, "expected :: after identifier in lambda")
		return nil
	}
	p.nextToken() // skip ::

	typ := p.parseExpression()

	// Expect -> after type
	if p.peekToken.Type != lexer.ARROW {
		p.errors = append(p.errors, fmt.Sprintf("expected -> after type in lambda, got %s", p.peekToken.Literal))
		return nil
	}
	p.nextToken() // curToken is now ->
	p.nextToken() // curToken is now start of body

	body := p.parseExpression()
	return &ast.Lambda{Var: name, Type: typ, Body: body}
}

func (p *Parser) parseLet() ast.Expr {
	p.nextToken() // skip let
	if p.curToken.Type != lexer.IDENT {
		return nil
	}
	name := p.curToken.Literal
	p.nextToken() // skip ident

	if p.curToken.Type != lexer.ASSIGN {
		p.errors = append(p.errors, "expected = in let binding")
		return nil
	}
	p.nextToken() // skip =

	val := p.parseExpression()

	// Expect 'in' after val
	if p.peekToken.Type != lexer.IN {
		p.errors = append(p.errors, fmt.Sprintf("expected 'in' after let expression, got %s", p.peekToken.Literal))
		return nil
	}
	p.nextToken() // curToken is now IN
	p.nextToken() // curToken is now start of body

	body := p.parseExpression()
	return &ast.Let{Var: name, Expr: val, In: body}
}

func (p *Parser) parseApplication() ast.Expr {
	expr := p.parsePrimaryExpression()

	// Simple application parsing (left-associative)
	// Stop at terminators that end an application sequence
	count := 0
	for p.peekToken.Type != lexer.EOF &&
		p.peekToken.Type != lexer.DOUBLE_COLON &&
		p.peekToken.Type != lexer.ARROW &&
		p.peekToken.Type != lexer.IN &&
		p.peekToken.Type != lexer.RPAREN &&
		p.peekToken.Type != lexer.COMMA {

		count++
		if count > 10000 {
			panic(fmt.Sprintf("Infinite loop in parseApplication! peek=%s", p.peekToken.Type))
		}

		fmt.Printf("DEBUG: parseApplication loop peek=%s\n", p.peekToken.Type)
		p.nextToken()
		arg := p.parsePrimaryExpression()
		if arg == nil {
			break
		}
		expr = &ast.App{Fn: expr, Arg: arg}
	}

	return expr
}

func (p *Parser) parsePrimaryExpression() ast.Expr {
	switch p.curToken.Type {
	case lexer.IDENT:
		return &ast.Var{Name: p.curToken.Literal}
	case lexer.NAT_LIT:
		if p.curToken.Literal == "0" {
			return &ast.Zero{}
		}
		p.errors = append(p.errors, "only 0 is supported as literal for Nat, use S(0) for others")
		return nil
	case lexer.NAT:
		return &ast.Nat{}
	case lexer.S_CON:
		return p.parseSucc()
	case lexer.REC:
		return p.parseRec()
	case lexer.MU:
		return p.parseMu()
	case lexer.LPAREN:
		return p.parseGroupedExpression()
	default:
		p.errors = append(p.errors, fmt.Sprintf("unexpected token: %s", p.curToken.Literal))
		return nil
	}
}

func (p *Parser) parseSucc() ast.Expr {
	p.nextToken() // skip S
	if p.curToken.Type != lexer.LPAREN {
		p.errors = append(p.errors, "expected ( after S")
		return nil
	}
	p.nextToken() // skip (

	inner := p.parseExpression()

	if p.peekToken.Type != lexer.RPAREN {
		p.errors = append(p.errors, "expected ) after S expression")
		return nil
	}
	p.nextToken() // curToken is now )

	return &ast.Succ{Expr: inner}
}

func (p *Parser) parseRec() ast.Expr {
	p.nextToken() // skip rec
	if p.curToken.Type != lexer.LPAREN {
		p.errors = append(p.errors, "expected ( after rec")
		return nil
	}
	p.nextToken() // skip (

	n := p.parseExpression()

	if p.peekToken.Type != lexer.COMMA {
		p.errors = append(p.errors, "expected , after n in rec")
		return nil
	}
	p.nextToken() // curToken is now ,
	p.nextToken() // skip ,

	base := p.parseExpression()

	if p.peekToken.Type != lexer.COMMA {
		p.errors = append(p.errors, "expected , after base in rec")
		return nil
	}
	p.nextToken() // curToken is now ,
	p.nextToken() // skip ,

	step := p.parseExpression()

	if p.peekToken.Type != lexer.RPAREN {
		p.errors = append(p.errors, "expected ) after rec arguments")
		return nil
	}
	p.nextToken() // curToken is now )

	return &ast.Rec{N: n, Base: base, Step: step}
}

func (p *Parser) parseMu() ast.Expr {
	p.nextToken() // skip mu
	if p.curToken.Type != lexer.LPAREN {
		p.errors = append(p.errors, "expected ( after mu")
		return nil
	}
	p.nextToken() // skip (

	body := p.parseExpression()

	if p.peekToken.Type != lexer.RPAREN {
		p.errors = append(p.errors, "expected ) after mu body")
		return nil
	}
	p.nextToken() // curToken is now )

	return &ast.Mu{Body: body}
}

func (p *Parser) parseGroupedExpression() ast.Expr {
	p.nextToken() // skip (

	// Check for Pi type (x :: A) -> B
	if p.curToken.Type == lexer.IDENT && p.peekToken.Type == lexer.DOUBLE_COLON {
		name := p.curToken.Literal
		p.nextToken() // skip ident
		p.nextToken() // skip ::
		typ := p.parseExpression()

		if p.peekToken.Type != lexer.RPAREN {
			p.errors = append(p.errors, "expected ) to close Pi type param")
			return nil
		}
		p.nextToken() // curToken is )

		if p.peekToken.Type != lexer.ARROW {
			// This might just be (x :: A) which is not a Pi type but a grouped expression?
			// But for now let's assume it's Pi if we see IDENT :: ...
			p.errors = append(p.errors, "expected -> after Pi type param")
			return nil
		}
		p.nextToken() // curToken is ->
		p.nextToken() // curToken is start of body

		body := p.parseExpression()
		return &ast.Pi{Var: name, Type: typ, Body: body}
	}

	expr := p.parseExpression()

	if p.peekToken.Type != lexer.RPAREN {
		p.errors = append(p.errors, "expected ) after expression")
		return nil
	}
	p.nextToken() // curToken is )

	return expr
}
