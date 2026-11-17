package types

import (
	"fmt"
	"rekursion/ast"
)

type Environment map[string]ast.Expr

type Checker struct {
	env Environment
}

func New() *Checker {
	return &Checker{env: make(Environment)}
}

func (c *Checker) Check(expr ast.Expr, expectedType ast.Expr) error {
	inferred, err := c.Infer(expr)
	if err != nil {
		return err
	}
	if !c.Equal(inferred, expectedType) {
		return fmt.Errorf("type mismatch: expected %s, got %s", expectedType, inferred)
	}
	return nil
}

func (c *Checker) Infer(expr ast.Expr) (ast.Expr, error) {
	switch e := expr.(type) {
	case *ast.Nat:
		return &ast.Nat{}, nil // Typeless Nat for now, or use a "Universe" type
	case *ast.Zero:
		return &ast.Nat{}, nil
	case *ast.Succ:
		if err := c.Check(e.Expr, &ast.Nat{}); err != nil {
			return nil, err
		}
		return &ast.Nat{}, nil
	case *ast.Var:
		if t, ok := c.env[e.Name]; ok {
			return t, nil
		}
		return nil, fmt.Errorf("undefined variable: %s", e.Name)
	case *ast.Lambda:
		// To infer type of \x: T. b, we need T to be a type
		// For now assume T is a type expression
		c.env[e.Var] = e.Type
		bodyType, err := c.Infer(e.Body)
		if err != nil {
			delete(c.env, e.Var)
			return nil, err
		}
		delete(c.env, e.Var)
		return &ast.Pi{Var: e.Var, Type: e.Type, Body: bodyType}, nil
	case *ast.Pi:
		// Pi type itself usually has type Universe (Star)
		return &ast.Nat{}, nil // Placeholder for Universe
	case *ast.App:
		fnType, err := c.Infer(e.Fn)
		if err != nil {
			return nil, err
		}
		pi, ok := fnType.(*ast.Pi)
		if !ok {
			return nil, fmt.Errorf("not a function type: %s", fnType)
		}
		if err := c.Check(e.Arg, pi.Type); err != nil {
			return nil, err
		}
		// Dependent type substitution: B[x := arg]
		return c.Substitute(pi.Body, pi.Var, e.Arg), nil
	case *ast.Rec:
		if err := c.Check(e.N, &ast.Nat{}); err != nil {
			return nil, err
		}
		baseType, err := c.Infer(e.Base)
		if err != nil {
			return nil, err
		}
		// Step type should be Nat -> BaseType -> BaseType
		// Actually for primitive recursion it might be more complex if dependent
		// For simplicity: Nat -> T -> T
		expectedStep := &ast.Pi{Var: "n", Type: &ast.Nat{}, Body: &ast.Pi{Var: "p", Type: baseType, Body: baseType}}
		if err := c.Check(e.Step, expectedStep); err != nil {
			return nil, err
		}
		return baseType, nil
	case *ast.Mu:
		// mu(f) where f: Nat -> Nat
		expectedF := &ast.Pi{Var: "n", Type: &ast.Nat{}, Body: &ast.Nat{}}
		if err := c.Check(e.Body, expectedF); err != nil {
			return nil, err
		}
		return &ast.Nat{}, nil
	case *ast.Let:
		valType, err := c.Infer(e.Expr)
		if err != nil {
			return nil, err
		}
		c.env[e.Var] = valType
		resType, err := c.Infer(e.In)
		delete(c.env, e.Var)
		return resType, err
	default:
		return nil, fmt.Errorf("unknown expression type: %T", e)
	}
}

func (c *Checker) Equal(t1, t2 ast.Expr) bool {
	// Simple structural equality after normalization
	n1 := c.Normalize(t1)
	n2 := c.Normalize(t2)
	return n1.String() == n2.String()
}

func (c *Checker) Normalize(expr ast.Expr) ast.Expr {
	// Very basic normalization (beta-reduction)
	switch e := expr.(type) {
	case *ast.App:
		fn := c.Normalize(e.Fn)
		arg := c.Normalize(e.Arg)
		if lam, ok := fn.(*ast.Lambda); ok {
			return c.Normalize(c.Substitute(lam.Body, lam.Var, arg))
		}
		return &ast.App{Fn: fn, Arg: arg}
	case *ast.Lambda:
		return &ast.Lambda{Var: e.Var, Type: c.Normalize(e.Type), Body: c.Normalize(e.Body)}
	case *ast.Pi:
		return &ast.Pi{Var: e.Var, Type: c.Normalize(e.Type), Body: c.Normalize(e.Body)}
	case *ast.Succ:
		return &ast.Succ{Expr: c.Normalize(e.Expr)}
	case *ast.Rec:
		n := c.Normalize(e.N)
		base := c.Normalize(e.Base)
		step := c.Normalize(e.Step)
		if _, ok := n.(*ast.Zero); ok {
			return base
		}
		if s, ok := n.(*ast.Succ); ok {
			// rec(S(n), base, step) = step n rec(n, base, step)
			return c.Normalize(&ast.App{
				Fn:  &ast.App{Fn: step, Arg: s.Expr},
				Arg: &ast.Rec{N: s.Expr, Base: base, Step: step},
			})
		}
		return &ast.Rec{N: n, Base: base, Step: step}
	default:
		return expr
	}
}

func (c *Checker) Substitute(expr ast.Expr, name string, val ast.Expr) ast.Expr {
	switch e := expr.(type) {
	case *ast.Var:
		if e.Name == name {
			return val
		}
		return e
	case *ast.Lambda:
		if e.Var == name {
			return e
		}
		return &ast.Lambda{Var: e.Var, Type: c.Substitute(e.Type, name, val), Body: c.Substitute(e.Body, name, val)}
	case *ast.Pi:
		if e.Var == name {
			return e
		}
		return &ast.Pi{Var: e.Var, Type: c.Substitute(e.Type, name, val), Body: c.Substitute(e.Body, name, val)}
	case *ast.App:
		return &ast.App{Fn: c.Substitute(e.Fn, name, val), Arg: c.Substitute(e.Arg, name, val)}
	case *ast.Succ:
		return &ast.Succ{Expr: c.Substitute(e.Expr, name, val)}
	case *ast.Rec:
		return &ast.Rec{
			N:    c.Substitute(e.N, name, val),
			Base: c.Substitute(e.Base, name, val),
			Step: c.Substitute(e.Step, name, val),
		}
	case *ast.Mu:
		return &ast.Mu{Body: c.Substitute(e.Body, name, val)}
	case *ast.Let:
		if e.Var == name {
			return &ast.Let{Var: e.Var, Expr: c.Substitute(e.Expr, name, val), In: e.In}
		}
		return &ast.Let{Var: e.Var, Expr: c.Substitute(e.Expr, name, val), In: c.Substitute(e.In, name, val)}
	default:
		return e
	}
}
