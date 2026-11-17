namespace FSharpLearning

module Collections =

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Collections & Functional Data Pipelines"
        printfn "=================================================="

        // 1. Lists (Immutable Singly-Linked Lists)
        // In F#, lists use semicolons as separators!
        let emptyList = []
        let fruits = ["Apple"; "Banana"; "Cherry"]

        // Prepending with 'cons' operator (::) is O(1)
        let allFruits = "Avocado" :: fruits

        // Concatenating with (@) is O(N)
        let moreFruits = allFruits @ ["Elderberry"; "Fig"]

        printfn "Fruits: %A" moreFruits
        printfn "Head: %s, Tail: %A" moreFruits.Head moreFruits.Tail
        printfn "Length: %d" moreFruits.Length

        // 2. Arrays (Mutable, contiguous memory, fast random access)
        let numbersArray = [| 10; 20; 30; 40 |]
        printfn "Array element at index 1: %d" numbersArray[1]
        numbersArray[1] <- 99 // Mutable in-place update
        printfn "Updated array: %A" numbersArray

        // 3. Sequences (seq<'T> - Lazy, IEnumerable<'T> equivalent)
        // Computed on-demand, ideal for large or infinite datasets.
        let infiniteEvens = Seq.initInfinite (fun i -> i * 2)
        let firstFiveEvens = infiniteEvens |> Seq.take 5 |> Seq.toList
        printfn "First 5 evens from infinite seq: %A" firstFiveEvens

        // 4. List and Sequence Comprehensions
        let squaresUnderFifty = 
            [ for i in 1 .. 10 do
                let sq = i * i
                if sq < 50 then
                    yield sq ]
        printfn "Comprehension squares (< 50): %A" squaresUnderFifty

        // Compact syntax with '->'
        let gridCoordinates = [ for x in 1 .. 2 do for y in 1 .. 2 -> (x, y) ]
        printfn "Grid coordinates: %A" gridCoordinates

        // 5. Common Collection Transformations (map, filter, fold, reduce)
        let sampleList = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10]

        // map: transform each element
        let doubled = sampleList |> List.map (fun x -> x * 2)

        // filter: keep elements matching a predicate
        let odds = sampleList |> List.filter (fun x -> x % 2 <> 0) // (<>) is not equal in F#

        // fold: accumulate state across elements
        // List.fold (fun accumulator element -> ...) initialValue list
        let sumViaFold = sampleList |> List.fold (fun acc x -> acc + x) 0
        let productViaFold = sampleList |> List.fold (*) 1

        printfn "Doubled: %A" doubled
        printfn "Odds: %A" odds
        printfn "Sum via fold: %d, Product via fold: %d" sumViaFold productViaFold

        // choose: combines map and filter using Option (keeps Some, discards None)
        let tryParseInt (s: string) : int option =
            match System.Int32.TryParse(s) with
            | true, v -> Some v
            | false, _ -> None

        let mixedInputs = ["42"; "invalid"; "100"; "abc"; "7"]
        let parsedNumbers = mixedInputs |> List.choose tryParseInt
        printfn "Parsed with choose: %A" parsedNumbers

        // groupBy & partition
        let groupedByEven = sampleList |> List.groupBy (fun x -> x % 2 = 0)
        printfn "Grouped by isEven: %A" groupedByEven

        let (evenList, oddList) = sampleList |> List.partition (fun x -> x % 2 = 0)
        printfn "Evens partition: %A, Odds partition: %A" evenList oddList

        // 6. Maps (Immutable Key-Value Dictionaries)
        let capitalMap = 
            [ ("France", "Paris"); ("Japan", "Tokyo"); ("Canada", "Ottawa") ]
            |> Map.ofList

        let updatedMap = capitalMap |> Map.add "Germany" "Berlin"

        match updatedMap |> Map.tryFind "Japan" with
        | Some capital -> printfn "Found capital: %s" capital
        | None -> printfn "Capital not found"

        // 7. Sets (Immutable Unique Element Collections)
        let setA = set [1; 2; 3; 4; 5]
        let setB = set [4; 5; 6; 7; 8]

        let unionSet = Set.union setA setB
        let intersectSet = Set.intersect setA setB
        let diffSet = Set.difference setA setB

        printfn "Union: %A" unionSet
        printfn "Intersection: %A" intersectSet
        printfn "Difference (A - B): %A" diffSet
