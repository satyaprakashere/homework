//go:build ignore
package main

import ("fmt"; "strings")

func isValid(s string) bool {
	stack := []rune {}
	lparen := "({["
	rparen := map[rune]rune {'}' : '{', ')' : '(', ']' : '['}
	for _, c := range s {
		exists := strings.Contains(lparen, string(c))
		if exists {
			stack = append(stack, c)
		} else if len(stack) > 0 &&  stack[len(stack)-1] == rparen[c] {
			stack = stack[:len(stack)-1]
		} else {
			return false
		}
	}

	if len(stack) == 0 {
		return true
	} else {
		return false
	}
}

func main() {
	fmt.Println(isValid("([])"))
}
