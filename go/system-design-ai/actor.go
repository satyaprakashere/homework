//go:build ignore
package main

import (
    "fmt"
    "log"
    "time"
)

// Message payload for the actor
type Message struct {
    Data string
}

// SuperviseActor wraps the actor in a recovery loop
func SuperviseActor(inbox <-chan Message) {
    for {
        // Run the actor instance
        runActor(inbox)
        
        // If runActor returns normally or panics, we land here:
        log.Println("[SUPERVISOR] Actor stopped or crashed. Restarting in 500ms...")
        time.Sleep(500 * time.Millisecond)
    }
}

// runActor represents a single lifecycle of the actor
func runActor(inbox <-chan Message) {
    // 1. Setup panic recovery (The Supervisor Hook)
    defer func() {
        if r := recover(); r != nil {
            log.Printf("[SUPERVISOR CATCH] Actor crashed with panic: %v", r)
        }
    }()
    
    log.Println("[ACTOR] Started and listening for messages...")
    
    // 2. Main Actor Loop
    for msg := range inbox {
        if msg.Data == "BOOM" {
            panic("simulated fatal error in actor!")
        }
        fmt.Printf("[ACTOR] Processed: %s\n", msg.Data)
    }
}

func main() {
    inbox := make(chan Message, 10)
    
    // Start the supervised actor
    go SuperviseActor(inbox)
    
    // Send normal messages
    inbox <- Message{Data: "Hello"}
    inbox <- Message{Data: "World"}
    time.Sleep(100 * time.Millisecond)
    
    // Send crashing message
    inbox <- Message{Data: "BOOM"}
    time.Sleep(100 * time.Millisecond)
    
    // Send message after crash — actor should have restarted automatically!
    inbox <- Message{Data: "I survived!"}
    
    time.Sleep(1 * time.Second)
    inbox <- Message{Data: "Still Alive!"}
    time.Sleep(1 * time.Second)
}