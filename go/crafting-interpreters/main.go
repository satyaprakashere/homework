package main

import (
	"fmt"
	"os"
	"rekursion/codegen"
	"rekursion/lexer"
	"rekursion/parser"
	"rekursion/types"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: rekursion <source_code>")
		os.Exit(1)
	}

	input := os.Args[1]
	if dat, err := os.ReadFile(input); err == nil {
		input = string(dat)
		fmt.Printf("Read source from file: %s\n", os.Args[1])
	} else {
		fmt.Println("Reading source from argument string")
	}

	fmt.Println("Starting Lexer...")
	l := lexer.New(input)
	fmt.Println("Starting Parser...")
	p := parser.New(l)
	fmt.Println("Parsing program...")
	expr := p.ParseProgram()
	fmt.Println("Parsing complete.")

	if len(p.Errors()) > 0 {
		fmt.Printf("Parser errors: %v\n", p.Errors())
		os.Exit(1)
	}

	checker := types.New()
	typ, err := checker.Infer(expr)
	if err != nil {
		fmt.Printf("Type error: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Inferred type: %s\n", typ)

	gen := codegen.New()
	binary, err := gen.Generate(expr)
	if err != nil {
		fmt.Printf("Codegen error: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Successfully generated %d bytes of Wasm\n", len(binary))
}
