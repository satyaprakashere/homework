//go:build ignore
package main

import ("fmt"; "sync"; "time")

func main() {
    ic := make(Tchan, 1)
    var wg sync.WaitGroup
    wg.Add(1)
    
    ic <- 300
    go ic.consume(&wg)
    go ic.produce()
    
    fmt.Println("Hello from chan")
    wg.Wait()
}

func (t Tchan) produce() {
    t <- 100
    t <- 200
    ms := time.Now().UnixMilli()
    for {
        t <- int(time.Now().UnixMilli() - ms)
        time.Sleep(1000 * time.Millisecond)
    }
//  close(t)
}

func (t Tchan) consume(wg *sync.WaitGroup) {
    defer wg.Done()
    for val := range t {
        fmt.Println(val)
    }
}

type Tchan chan int