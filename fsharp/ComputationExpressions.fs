namespace FSharpLearning

module ComputationExpressions =

    // Computation expressions provide a unified, composable syntax for computational workflows
    // such as async, tasks, sequences, queries, and monadic error-handling.
    // They work by implementing a builder class with special methods like Bind, Return, ReturnFrom, Zero, etc.

    // 1. Defining a custom OptionBuilder for Option workflows
    type OptionBuilder() =
        // Bind unwraps an Option<'T>, and if Some, passes it to the continuation function
        member this.Bind(m: 'T option, f: 'T -> 'U option) : 'U option =
            match m with
            | Some v -> f v
            | None -> None

        // Return wraps a raw value into Some 'T
        member this.Return(x: 'T) : 'T option =
            Some x

        // ReturnFrom passes through an already wrapped Option<'T>
        member this.ReturnFrom(m: 'T option) : 'T option =
            m

        // Zero handles empty branches (e.g. if without else)
        member this.Zero() : unit option =
            Some ()

    // Instantiate builder
    let option = OptionBuilder()

    // Helper functions returning Option
    let tryDivide (numerator: float) (denominator: float) : float option =
        if denominator = 0.0 then None else Some (numerator / denominator)

    let trySqrt (x: float) : float option =
        if x < 0.0 then None else Some (System.Math.Sqrt x)

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Custom Computation Expressions"
        printfn "=================================================="

        // A. Without Computation Expressions (Nested pattern matching pyramid of doom)
        let calculatePyramidOfDoom a b c =
            match tryDivide a b with
            | None -> None
            | Some step1 ->
                match tryDivide step1 c with
                | None -> None
                | Some step2 ->
                    match trySqrt step2 with
                    | None -> None
                    | Some step3 -> Some step3

        // B. With our custom 'option' Computation Expression:
        // 'let!' automatically calls builder.Bind behind the scenes!
        let calculateClean a b c =
            option {
                let! step1 = tryDivide a b
                let! step2 = tryDivide step1 c
                let! step3 = trySqrt step2
                return step3
            }

        printfn "Nested match result (100 / 2 / 2 = 25 -> sqrt = 5): %A" 
            (calculatePyramidOfDoom 100.0 2.0 2.0)
        printfn "Option builder result: %A" 
            (calculateClean 100.0 2.0 2.0)

        // Handling failure cleanly: division by zero or negative sqrt
        printfn "Division by zero failure: %A" 
            (calculateClean 100.0 0.0 2.0)
        printfn "Negative square root failure: %A" 
            (calculateClean -100.0 2.0 2.0)
