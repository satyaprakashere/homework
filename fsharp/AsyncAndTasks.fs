namespace FSharpLearning

open System.Threading.Tasks

module AsyncAndTasks =

    // Simulated I/O operation returning an Async<'T> (Cold task)
    let fetchUserDataAsync (userId: int) : Async<string> =
        async {
            do! Async.Sleep 50 // Non-blocking asynchronous delay
            return $"User #{userId} (Fetched via Async)"
        }

    // Simulated I/O operation returning a Task<'T> (Hot Task, standard .NET interop)
    let fetchProductDataTask (productId: int) : Task<string> =
        task {
            do! Task.Delay 50
            return $"Product #{productId} (Fetched via Task)"
        }

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Asynchronous Programming (Async & Task)"
        printfn "=================================================="

        // 1. Running an Async workflow synchronously at the boundary
        let userResult = fetchUserDataAsync 42 |> Async.RunSynchronously
        printfn "Async result: %s" userResult

        // 2. Parallel Async Execution using Async.Parallel
        let userIds = [101; 102; 103; 104]
        let parallelFetch =
            userIds
            |> List.map fetchUserDataAsync
            |> Async.Parallel

        let allUsers = parallelFetch |> Async.RunSynchronously
        printfn "Parallel Async results: %A" allUsers

        // 3. Modern Task Computation Expression (.NET Task / Task<T> Interop)
        let runTaskExample () =
            task {
                let! product = fetchProductDataTask 999
                printfn "Task result: %s" product
                return product
            }

        // Wait for the Task synchronously at the top-level test runner
        (runTaskExample ()).GetAwaiter().GetResult() |> ignore

        // 4. Exception Handling in Async
        let riskyOperation (shouldFail: bool) : Async<string> =
            async {
                if shouldFail then
                    return raise (System.InvalidOperationException("Simulated network failure"))
                else
                    return "Success from remote service"
            }

        let handledOperation : Async<unit> =
            async {
                try
                    let! res = riskyOperation true
                    printfn "Received: %s" res
                with
                | :? System.InvalidOperationException as ex ->
                    printfn "Caught expected async exception: %s" ex.Message
            }

        handledOperation |> Async.RunSynchronously
