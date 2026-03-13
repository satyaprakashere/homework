//go:build ignore

package main

import "fmt"

func main() {
	cache := make(map[string]string)
	cache["key"] = "value"
	delete(cache, "key")

	invalidation := &Invalidation{}
	invalidation.invalidate(cache, "key")
	fmt.Println(cache)

}

type Invalidation struct {
	cache map[string]string
}

func (i *Invalidation) invalidate(cache map[string]string, key string) {
	delete(cache, key)
	fmt.Println("Cache invalidated")
}
