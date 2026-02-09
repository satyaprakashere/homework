//go:build ignore
package main

import "fmt"

func main() {
  fmt.Println(romanToInt("MCMXCIV"))
}

func romanToInt(s string) int {
  result := 0
  prevValue := 0
  for _, v := range s {
    if currentValue, ok := roman[v]; ok {
      if currentValue > prevValue {
        result += currentValue - 2*prevValue // Subtraction case
      } else {
        result += currentValue // Addition case
      }
      prevValue = currentValue
    }
  }
  return result
}

var roman = map[rune]int{
  'I': 1,
  'V': 5,
  'X': 10,
  'L': 50,
  'C': 100,
  'D': 500,
  'M': 1000,
}