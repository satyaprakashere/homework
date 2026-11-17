//go:build ignore

package main

import (
	"context"
	"fmt"
)

func main() {
	ctx := context.Background()
	ctx.Deadline()

	fmt.Println(ctx)
}
