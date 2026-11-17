namespace FSharpLearning

module Program =

    let printHelp () =
        printfn "=================================================="
        printfn "           F# Learning Showcase CLI"
        printfn "=================================================="
        printfn "Usage: dotnet run [module-name]"
        printfn ""
        printfn "Available modules:"
        printfn "  all           - Run all learning modules (default)"
        printfn "  basics        - Immutability, types, string interpolation, expressions"
        printfn "  functions     - Currying, pipes (|>, >>), lambdas, tail recursion"
        printfn "  collections   - Lists, arrays, seq, maps, sets, comprehensions"
        printfn "  domain        - Records, discriminated unions, state machines"
        printfn "  matching      - Pattern matching, guards, active patterns"
        printfn "  units         - Units of measure (compile-time dimensional analysis)"
        printfn "  rop           - Railway Oriented Programming (Result<'T, 'E>)"
        printfn "  async         - Async workflows, Task<'T>, parallel processing"
        printfn "  oo            - Classes, interfaces, object expressions, extensions"
        printfn "  monad         - Custom computation expressions (OptionBuilder)"
        printfn "  help          - Show this help message"
        printfn "=================================================="

    let runAll () =
        Basics.run ()
        Functions.run ()
        Collections.run ()
        DomainModeling.run ()
        PatternMatching.run ()
        UnitsOfMeasure.run ()
        RailwayOrientedProgramming.run ()
        AsyncAndTasks.run ()
        ObjectOriented.run ()
        ComputationExpressions.run ()

    [<EntryPoint>]
    let main argv =
        let target = 
            if argv.Length > 0 then argv[0].ToLowerInvariant() 
            else "all"

        match target with
        | "all" -> 
            runAll ()
            0
        | "basics" -> 
            Basics.run ()
            0
        | "functions" -> 
            Functions.run ()
            0
        | "collections" -> 
            Collections.run ()
            0
        | "domain" | "types" -> 
            DomainModeling.run ()
            0
        | "matching" | "patterns" -> 
            PatternMatching.run ()
            0
        | "units" | "measures" -> 
            UnitsOfMeasure.run ()
            0
        | "rop" | "railway" -> 
            RailwayOrientedProgramming.run ()
            0
        | "async" | "tasks" -> 
            AsyncAndTasks.run ()
            0
        | "oo" | "oop" -> 
            ObjectOriented.run ()
            0
        | "monad" | "builder" | "ce" -> 
            ComputationExpressions.run ()
            0
        | "help" | "--help" | "-h" -> 
            printHelp ()
            0
        | other -> 
            printfn "Unknown module: '%s'" other
            printHelp ()
            1
