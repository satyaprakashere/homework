namespace FSharpLearning

module Basics =

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Basics"
        printfn "=================================================="

        // 1. Immutability & Value Binding
        // In F#, values are immutable by default using the 'let' keyword.
        let greeting = "Hello, F# World!"
        let answer = 42
        let pi = 3.14159
        let isFunctional = true

        printfn "%s" greeting
        printfn "Answer: %d, Pi: %.4f, Is Functional: %b" answer pi isFunctional

        // 2. Mutable Variables
        // Mutability is explicit with 'mutable' and updated with '<-'
        let mutable counter = 0
        counter <- counter + 1
        printfn "Updated mutable counter: %d" counter

        // 3. Type Inference & Explicit Type Annotations
        // F# infers types automatically, but you can explicitly annotate them when helpful.
        let explicitInt: int = 100
        let explicitString: string = "Typed explicitly"
        let floatFromInt = float explicitInt // Explicit conversion (no implicit casting in F#)
        printfn "Explicit float conversion: %.1f (%s)" floatFromInt explicitString

        // 4. String Formatting & Interpolation
        // F# supports string interpolation with '$' and printf-style specifiers.
        let name = "Alice"
        let age = 30
        let interpolated = $"Name: {name}, Age: {age}, Next year: {age + 1}"
        let formattedInterpolated = $"Pi to 2 decimals: {pi:F2}"
        printfn "%s" interpolated
        printfn "%s" formattedInterpolated

        // Triple-quoted strings preserve newlines and quotes verbatim
        let multilineJson = """{ "name": "Alice", "active": true }"""
        printfn "JSON payload:\n%s" multilineJson

        // 5. Control Flow: If/Then/Else Expressions
        // In F#, 'if' is an expression returning a value, not an imperative statement.
        // Both branches must return the same type.
        let number = 15
        let parityMessage = 
            if number % 2 = 0 then
                "even"
            else
                "odd"

        printfn "%d is %s" number parityMessage

        // 6. Scope and Shadowing
        // Inner let-bindings can shadow outer bindings cleanly.
        let x = 10
        let shadowExample =
            let x = 20
            let x = x * 2
            x
        printfn "Outer x: %d, Shadowed inner result: %d" x shadowExample

        // 7. Unit Type
        // 'unit' represents the absence of a meaningful value (similar to 'void' in C#, but an actual 1-value type: '()')
        let printSeparator () : unit =
            printfn "--------------------------------------------------"

        printSeparator ()
