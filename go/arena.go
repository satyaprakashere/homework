//go:build ignore
package main

//import "fmt"
import "arena"

func unsafeUse() []int {
   a := arena.NewArena()
   defer a.Free()
    
   // Slice becomes invalid once Free is called
   return arena.MakeSlice[int](a, 3, 3)
}

func main() {
   data := unsafeUse()
   println(len(data)) // Accessing invalid memory
}
