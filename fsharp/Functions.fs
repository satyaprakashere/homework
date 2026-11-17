namespace FSharpLearning

module Functions =

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Functions & Composition"
        printfn "=================================================="

        // 1. Basic Function Definition
        // F# uses whitespace and indentation for scoping.
        let add a b = a + b
        let square x = x * x

        printfn "add 3 5 = %d" (add 3 5)
        printfn "square 4 = %d" (square 4)

        // 2. Currying & Partial Application
        // In F#, all functions are automatically curried: (a -> b -> c) is a -> (b -> c).
        // Calling a function with fewer arguments than expected returns a new function!
        let addTen = add 10       // Partial application: returns int -> int
        let multiply a b = a * b
        let double = multiply 2   // int -> int

        printfn "addTen 25 = %d" (addTen 25)
        printfn "double 7 = %d" (double 7)

        // 3. Pipe-Forward Operator (|>)
        // The pipe operator passes the result of the left-hand expression as the last argument
        // to the right-hand function: x |> f is equivalent to f(x).
        // Eliminates deeply nested parentheses: f(g(h(x))) becomes x |> h |> g |> f.
        let calculated = 
            5
            |> addTen      // 15
            |> double      // 30
            |> square      // 900

        printfn "Piped calculation (5 |> addTen |> double |> square) = %d" calculated

        // 4. Function Composition Operator (>>)
        // Forward composition: (f >> g)(x) is equivalent to g(f(x)).
        // Combines two functions into a single new reusable function.
        let addTenThenDouble = addTen >> double
        let processNumber = addTen >> double >> square

        printfn "Composed function on 5 = %d" (processNumber 5)

        // Backward composition (<<): (g << f)(x) = g(f(x))
        let negate x = -x
        let squareThenNegate = negate << square
        printfn "squareThenNegate 4 = %d" (squareThenNegate 4)

        // 5. Lambda Expressions (Anonymous Functions)
        // Syntax: fun param1 param2 -> body
        let numbers = [1; 2; 3; 4; 5]
        let incremented = numbers |> List.map (fun x -> x + 1)
        let evens = numbers |> List.filter (fun x -> x % 2 = 0)

        printfn "Incremented with lambda: %A" incremented
        printfn "Filtered evens with lambda: %A" evens

        // 6. Recursion ('rec') and Tail Recursion
        // In F#, recursive functions must explicitly use 'rec'.
        // Standard recursion (can cause stack overflow for very large N):
        let rec factorialNaive n =
            if n <= 1 then 1
            else n * factorialNaive (n - 1)

        printfn "factorialNaive 5 = %d" (factorialNaive 5)

        // Tail recursion: accumulator pattern. The compiler optimizes this into a loop!
        let factorialTailRec n =
            let rec loop acc current =
                if current <= 1 then acc
                else loop (acc * current) (current - 1)
            loop 1 n

        printfn "factorialTailRec 5 = %d" (factorialTailRec 5)

        // 7. Higher-Order Functions
        // Functions that take other functions as arguments or return functions.
        let applyTwice (f: 'a -> 'a) (x: 'a) : 'a =
            f (f x)

        let plusThree x = x + 3
        printfn "applyTwice plusThree 10 = %d" (applyTwice plusThree 10)

        let makeMultiplier factor =
            fun x -> x * factor

        let triple = makeMultiplier 3
        printfn "triple 9 = %d" (triple 9)
