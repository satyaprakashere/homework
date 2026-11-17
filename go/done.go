//go:build ignore
package main

import ("fmt"
    "time"
    "sync")

func main() {
    wg := sync.WaitGroup{}
    done := make(chan struct{})
    time.AfterFunc(3*time.Second, func() {
        close(done)
    })
    
    dogs := make(chan string, 100)
    cats := make(chan string, 100)
    
    wg.Go(func() { bark(done, dogs)})
    wg.Go(func() { meow(done, cats)})
    
    wg.Go(func() {
        for {
            select {
            case     <-done: return
            case s:= <-dogs: fmt.Println(s)
            case s:= <-cats: fmt.Println(s)
            }
        }
    })
    
    wg.Wait()
}

func bark(done chan struct{}, c chan string) {
    defer close(c)
    for {
        select {
        case   <-done       : return
        case c <-"Bark"     : time.Sleep(500 * time.Millisecond)
        }
    }
}

func meow(done chan struct{}, c chan string) {
    defer close(c)
    for {
        select {
        case    <-done      : return
        case c  <-"Meow"    : time.Sleep(500 * time.Millisecond)
        }
    }
}