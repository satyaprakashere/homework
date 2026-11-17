namespace FSharpLearning

module RailwayOrientedProgramming =

    type RawRegistration = {
        Username: string
        Email: string
        Age: int
    }

    type ValidatedUser = {
        UserId: System.Guid
        NormalizedUsername: string
        NormalizedEmail: string
        Age: int
    }

    type ValidationError =
        | UsernameBlank
        | UsernameTooLong of maxLength: int
        | InvalidEmail of reason: string
        | Underage of minimumAge: int

    // Switch functions ('a -> Result<'b, ValidationError>)
    let validateUsername (raw: RawRegistration) : Result<RawRegistration, ValidationError> =
        if System.String.IsNullOrWhiteSpace(raw.Username) then
            Error UsernameBlank
        elif raw.Username.Length > 20 then
            Error (UsernameTooLong 20)
        else
            Ok raw

    let validateEmail (raw: RawRegistration) : Result<RawRegistration, ValidationError> =
        if not (raw.Email.Contains("@") && raw.Email.Contains(".")) then
            Error (InvalidEmail "Must contain '@' and '.'")
        else
            Ok raw

    let validateAge (raw: RawRegistration) : Result<RawRegistration, ValidationError> =
        if raw.Age < 18 then
            Error (Underage 18)
        else
            Ok raw

    let createUser (raw: RawRegistration) : ValidatedUser =
        {
            UserId = System.Guid.NewGuid()
            NormalizedUsername = raw.Username.Trim()
            NormalizedEmail = raw.Email.Trim().ToLowerInvariant()
            Age = raw.Age
        }

    // Kleisli composition operator (>=>)
    let (>=>) f g = fun x ->
        match f x with
        | Ok result -> g result
        | Error err -> Error err

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Railway Oriented Programming (ROP)"
        printfn "=================================================="

        // 1. Pipeline with Result.bind
        let registerUserPipeline (raw: RawRegistration) : Result<ValidatedUser, ValidationError> =
            raw
            |> validateUsername
            |> Result.bind validateEmail
            |> Result.bind validateAge
            |> Result.map createUser

        // 2. Pipeline with Fish Operator (>=>)
        let fullValidationSwitch = validateUsername >=> validateEmail >=> validateAge
        let registerUserFish (raw: RawRegistration) =
            raw
            |> fullValidationSwitch
            |> Result.map createUser

        // Formatter for display
        let printResult label (res: Result<ValidatedUser, ValidationError>) =
            match res with
            | Ok user -> 
                printfn "[%s] OK -> User: %s <%s>, Age: %d (ID: %s)" 
                    label user.NormalizedUsername user.NormalizedEmail user.Age (user.UserId.ToString().Substring(0, 8))
            | Error err ->
                let msg = 
                    match err with
                    | UsernameBlank -> "Username cannot be empty"
                    | UsernameTooLong maxLen -> $"Username exceeds max length of {maxLen}"
                    | InvalidEmail reason -> $"Invalid email: {reason}"
                    | Underage minAge -> $"User must be at least {minAge} years old"
                printfn "[%s] FAILED -> %s" label msg

        let validRequest = { Username = "alice_fsharp"; Email = "alice@example.com"; Age = 25 }
        let blankUserRequest = { Username = ""; Email = "alice@example.com"; Age = 25 }
        let badEmailRequest = { Username = "bob"; Email = "invalid-email-address"; Age = 30 }
        let youngUserRequest = { Username = "charlie"; Email = "charlie@example.com"; Age = 16 }

        printResult "Valid Input" (registerUserPipeline validRequest)
        printResult "Empty Username" (registerUserPipeline blankUserRequest)
        printResult "Bad Email" (registerUserPipeline badEmailRequest)
        printResult "Underage User" (registerUserPipeline youngUserRequest)
        printResult "Via Fish Operator" (registerUserFish validRequest)
