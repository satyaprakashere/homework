package ast

import "fmt"

// Expr represents any Rekursion expression.
type Expr interface {
	exprNode()
	String() string
}

// Nat represents the natural number type.
type Nat struct{}

func (e *Nat) exprNode()      {}
func (e *Nat) String() string { return "Nat" }

// Zero represents the '0' constructor for Nat.
type Zero struct{}

func (e *Zero) exprNode()      {}
func (e *Zero) String() string { return "0" }

// Succ represents the 'S' (successor) constructor for Nat.
type Succ struct {
	Expr Expr
}

func (e *Succ) exprNode()      {}
func (e *Succ) String() string { return fmt.Sprintf("S(%s)", e.Expr) }

// Var represents a variable.
type Var struct {
	Name string
}

func (e *Var) exprNode()      {}
func (e *Var) String() string { return e.Name }

// Lambda represents an abstraction: \x: T. body
type Lambda struct {
	Var  string
	Type Expr
	Body Expr
}

func (e *Lambda) exprNode() {}
func (e *Lambda) String() string {
	return fmt.Sprintf("\\%s :: %s -> %s", e.Var, e.Type, e.Body)
}

// Pi represents a dependent function type: (x: A) -> B
type Pi struct {
	Var  string
	Type Expr
	Body Expr
}

func (e *Pi) exprNode() {}
func (e *Pi) String() string {
	return fmt.Sprintf("(%s :: %s) -> %s", e.Var, e.Type, e.Body)
}

// App represents function application: f x
type App struct {
	Fn  Expr
	Arg Expr
}

func (e *App) exprNode() {}
func (e *App) String() string {
	return fmt.Sprintf("(%s %s)", e.Fn, e.Arg)
}

// Rec represents primitive recursion: rec(n, base, step)
// step is usually a function \n. \prev. body
type Rec struct {
	N    Expr
	Base Expr
	Step Expr
}

func (e *Rec) exprNode() {}
func (e *Rec) String() string {
	return fmt.Sprintf("rec(%s, %s, %s)", e.N, e.Base, e.Step)
}

// Mu represents minimalization: mu(f)
// f is a function \n. body which returns 0 when condition is met.
type Mu struct {
	Body Expr
}

func (e *Mu) exprNode() {}
func (e *Mu) String() string {
	return fmt.Sprintf("mu(%s)", e.Body)
}

// Let represents local binding: let x = e in b
type Let struct {
	Var  string
	Expr Expr
	In   Expr
}

func (e *Let) exprNode() {}
func (e *Let) String() string {
	return fmt.Sprintf("let %s = %s in %s", e.Var, e.Expr, e.In)
}
