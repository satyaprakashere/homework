namespace FSharpLearning

module PatternMatching =

    type Coordinates3D = { X: float; Y: float; Z: float }

    // Multi-case active pattern: classifies an int as Even or Odd
    let (|Even|Odd|) input =
        if input % 2 = 0 then Even else Odd

    // Complete active pattern: FizzBuzz partition
    let (|Fizz|Buzz|FizzBuzz|Other|) n =
        match n % 3 = 0, n % 5 = 0 with
        | true, true -> FizzBuzz
        | true, false -> Fizz
        | false, true -> Buzz
        | false, false -> Other n

    // Partial active pattern: (|Integer|_|)
    let (|Integer|_|) (str: string) =
        match System.Int32.TryParse(str) with
        | true, v -> Some v
        | false, _ -> None

    let (|Float|_|) (str: string) =
        match System.Double.TryParse(str) with
        | true, v -> Some v
        | false, _ -> None

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Pattern Matching & Active Patterns"
        printfn "=================================================="

        // 1. Basic Value and Range Matching
        let describeNumber n =
            match n with
            | 0 -> "Zero"
            | 1 -> "One"
            | x when x < 0 -> "Negative"
            | x when x >= 2 && x <= 10 -> "Small positive (2-10)"
            | _ -> "Large positive"

        printfn "describeNumber 0: %s" (describeNumber 0)
        printfn "describeNumber -5: %s" (describeNumber -5)
        printfn "describeNumber 7: %s" (describeNumber 7)
        printfn "describeNumber 99: %s" (describeNumber 99)

        // 2. List Pattern Matching (Head :: Tail)
        let rec sumList (lst: int list) =
            match lst with
            | [] -> 0
            | head :: tail -> head + sumList tail

        let describeList lst =
            match lst with
            | [] -> "Empty list"
            | [single] -> $"Single item: {single}"
            | [first; second] -> $"Exactly two items: {first} and {second}"
            | first :: second :: rest -> $"At least two: {first}, {second}, and {rest.Length} more"

        printfn "sumList: %d" (sumList [1; 2; 3; 4; 5])
        printfn "describe: %s" (describeList [42])
        printfn "describe: %s" (describeList [10; 20])
        printfn "describe: %s" (describeList [1; 2; 3; 4])

        // 3. Record Matching with When Guards
        let classifyPoint pt =
            match pt with
            | { X = 0.0; Y = 0.0; Z = 0.0 } -> "Origin"
            | { Z = 0.0 } -> "On XY ground plane"
            | { X = x; Y = y; Z = z } when x = y && y = z -> $"On diagonal: {x}"
            | { X = x; Y = y; Z = z } -> $"General 3D point ({x}, {y}, {z})"

        printfn "Classify origin: %s" (classifyPoint { X = 0.0; Y = 0.0; Z = 0.0 })
        printfn "Classify ground: %s" (classifyPoint { X = 3.0; Y = 4.0; Z = 0.0 })
        printfn "Classify diagonal: %s" (classifyPoint { X = 5.0; Y = 5.0; Z = 5.0 })

        // 4. Multi-Case Active Patterns
        let checkParity n =
            match n with
            | Even -> $"{n} is Even"
            | Odd -> $"{n} is Odd"

        printfn "%s" (checkParity 4)
        printfn "%s" (checkParity 7)

        let fizzBuzz n =
            match n with
            | FizzBuzz -> "FizzBuzz"
            | Fizz -> "Fizz"
            | Buzz -> "Buzz"
            | Other x -> string x

        let sampleFizzBuzz = [1..15] |> List.map fizzBuzz |> String.concat ", "
        printfn "FizzBuzz (1-15): %s" sampleFizzBuzz

        // 5. Partial Active Patterns
        let parseStringInput input =
            match input with
            | Integer i -> $"Integer: {i * 2} (doubled)"
            | Float f -> $"Float: {f:F2}"
            | other -> $"Unknown text: '{other}'"

        printfn "Parse '42': %s" (parseStringInput "42")
        printfn "Parse '3.1415': %s" (parseStringInput "3.1415")
        printfn "Parse 'hello': %s" (parseStringInput "hello")

        // 6. Type Test Matching (:?)
        let inspectObject (obj: obj) =
            match obj with
            | :? int as i -> $"System.Int32: {i}"
            | :? string as s -> $"System.String: length {s.Length}"
            | :? (int list) as lst -> $"List of int with count {lst.Length}"
            | other -> $"Other type: {other.GetType().Name}"

        printfn "%s" (inspectObject 123)
        printfn "%s" (inspectObject "F# rocks")
        printfn "%s" (inspectObject [1; 2; 3])
