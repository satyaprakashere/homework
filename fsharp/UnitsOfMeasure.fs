namespace FSharpLearning

module UnitsOfMeasure =

    // Base Measures
    [<Measure>] type m        // meters
    [<Measure>] type s        // seconds
    [<Measure>] type kg       // kilograms
    [<Measure>] type ft       // feet

    // Derived Measures
    [<Measure>] type mps = m / s              // velocity (m/s)
    [<Measure>] type mps2 = m / s^2           // acceleration (m/s^2)
    [<Measure>] type N = kg * m / s^2         // force (Newtons)

    let square (x: float<'u>) : float<'u^2> = x * x
    let cube (x: float<'u>) : float<'u^3> = x * x * x

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Units of Measure (Zero-Cost Type Safety)"
        printfn "=================================================="

        // 1. Defining Measured Values
        let distance: float<m> = 100.0<m>
        let time: float<s> = 9.58<s> // Usain Bolt's 100m world record time

        // Division naturally produces m/s
        let speed: float<mps> = distance / time
        printfn "Distance: %.2f m" distance
        printfn "Time: %.2f s" time
        printfn "Average Speed: %.2f m/s" speed

        // Force calculation: F = m * a
        let mass: float<kg> = 80.0<kg>
        let acceleration: float<mps2> = 9.81<m/s^2>
        let force: float<N> = mass * acceleration
        printfn "Force: %.2f N" force

        // 2. Unit Conversion with Conversion Factors
        let feetPerMeter: float<ft/m> = 3.28084<ft/m>
        let distanceInFeet: float<ft> = distance * feetPerMeter
        printfn "Distance in feet: %.2f ft" distanceInFeet

        // 3. Generic Functions with Units of Measure
        let area = square 5.0<m> // returns float<m^2>
        let volume = cube 2.0<m> // returns float<m^3>

        printfn "Area: %.2f m^2" area
        printfn "Volume: %.2f m^3" volume

        // 4. Adding and Stripping Units
        let rawNumber = 42.0
        let measuredValue = rawNumber * 1.0<m>     // Add unit
        let strippedValue = float measuredValue    // Strip unit

        printfn "Measured: %A, Stripped raw float: %.1f" measuredValue strippedValue
