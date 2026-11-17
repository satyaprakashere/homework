//go:build ignore
package main

import (
  "fmt"
  "strings"
)

// Sutra represents a Pāṇinian rule
type Sutra struct {
  ID   string
  Name string
  Apply func(input string) (string, bool)
}

// Simple rule: Iko Yaṇaci (6.1.77) - i/u/ṛ/ḷ becomes y/v/r/l before a vowel
func ikoYanaci(input string) (string, bool) {
  // Simplified logic for i + u -> yu
  if strings.Contains(input, "इ + उ") {
    return strings.Replace(input, "इ + उ", "यु", 1), true
  }
  return input, false
}

func main() {
  word1 := "इति"
  word2 := "उवाच"
  combined := word1 + " + " + word2
  
  fmt.Printf("Input: %s\n", combined)
  fmt.Println("--- Derivation Steps ---")
  
  // Step 1: Apply 6.1.77
  result, applied := ikoYanaci(combined)
  if applied {
    fmt.Printf("Rule 6.1.77 (इको यणचि): %s\n", result)
  }
  
  // Final Output
  final := strings.ReplaceAll(result, " ", "")
  fmt.Printf("\nFinal Word: %s\n", final)
}