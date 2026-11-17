//go:build ignore
package main

import (
    "fmt"
    "context"
    "time"
    "sync"
)

func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
    defer cancel()
    
    wg := sync.WaitGroup{}
    
    dogs := make(chan string)
    cats := make(chan string)
    
    wg.Go(func() { bark(ctx, dogs)})
    wg.Go(func() { meow(ctx, cats)})
    
    wg.Go(func() {
        for {
            select {
            case        <-ctx.Done()    : return
            case s      := <-dogs       : fmt.Println("Dogs: ", s)
            case s, ok  := <-cats       : if !ok {
                cats = nil
                break
            }
                fmt.Println("Cats: ", s)
            }
        }

    })
    
    wg.Wait()
}

func bark(ctx context.Context, c chan string) {
    defer close(c)
    for {
        select {
        case   <-ctx.Done() : return
        case c <-"Bark"     : time.Sleep(500 * time.Millisecond)
        }
    }
}

func meow(ctx context.Context, c chan string) {
    defer close(c)
    for {
        select {
        case    <-ctx.Done()  : return
        case c  <-"Meow"      : time.Sleep(500 * time.Millisecond)
        }
    }
}