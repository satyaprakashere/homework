//go:build ignore
package main

import "fmt"

func main() {
	fmt.Println(romanToInt("MCMXCIV"))
}

func romanToInt(s string) int {
	res := 0
	i := 0
	for i<len(s) && s[i] == 'M' {
		res += 1000; i++
	}
	for i<len(s) && s[i] == 'D' {
		res += 500; i++
	}
	for i<len(s) && s[i] == 'C' {
		if i+1 < len(s) && s[i+1] =='D' {
			res += 400; i+=2
			continue
		}
		if i+1 < len(s) && s[i+1] =='M' {
			res += 900; i+=2
			continue
		}
		res += 100; i++
	}
	for i<len(s) && s[i] == 'L' {
		res += 50; i++
	}
	for i<len(s) && s[i] == 'X' {
		if i+1 < len(s) && s[i+1] =='L' {
			res += 40; i+=2
			continue
		}
		if i+1 < len(s) && s[i+1] =='C' {
			res += 90; i+=2
			continue
		}
		res += 10; i++
	}
	for i<len(s) && s[i] == 'V' {
		res += 5; i++
	}
	for i<len(s) && s[i] == 'I' {
		if i+1 < len(s) && s[i+1] =='V' {
			res += 4; i+=2
			continue
		}
		if i+1 < len(s) && s[i+1] =='X' {
			res += 9; i+=2
			continue
		}
		res += 1; i++
	}
	return res
}