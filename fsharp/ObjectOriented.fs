namespace FSharpLearning

module ObjectOriented =

    // Interface definition
    type IDescribable =
        abstract member Describe: unit -> string

    type IShape =
        inherit IDescribable
        abstract member Area: unit -> float
        abstract member Perimeter: unit -> float

    // Class definition with primary constructor
    type Circle(radius: float) =
        // Private member
        let pi = System.Math.PI

        // Constructor validation
        do
            if radius <= 0.0 then
                invalidArg (nameof radius) "Radius must be positive"

        // Public property
        member this.Radius = radius

        // Explicit interface implementation
        interface IShape with
            member this.Area() = pi * radius * radius
            member this.Perimeter() = 2.0 * pi * radius
            member this.Describe() = $"Circle with radius {radius:F2}"

    type Rectangle(width: float, height: float) =
        member this.Width = width
        member this.Height = height

        interface IShape with
            member this.Area() = width * height
            member this.Perimeter() = 2.0 * (width + height)
            member this.Describe() = $"Rectangle ({width:F2} x {height:F2})"

    // Type extension (Extension method on System.String)
    type System.String with
        member this.ToTitleCase() =
            System.Globalization.CultureInfo.CurrentCulture.TextInfo.ToTitleCase(this)

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Object-Oriented Features & .NET Interop"
        printfn "=================================================="

        // 1. Using Classes and Interfaces
        let circle = Circle(5.0)
        let rect = Rectangle(4.0, 6.0)

        // In F#, interface members are called explicitly via interface cast (:>)
        let shapes: IShape list = [ circle :> IShape; rect :> IShape ]

        for shape in shapes do
            printfn "%s -> Area: %.2f, Perimeter: %.2f" 
                (shape.Describe()) (shape.Area()) (shape.Perimeter())

        // 2. Object Expressions
        // Anonymous interface implementation on the fly without declaring a new class
        let customShape = 
            { new IShape with
                member this.Area() = 42.0
                member this.Perimeter() = 26.0
                member this.Describe() = "Custom dynamically defined shape" }

        printfn "Object expression: %s -> Area: %.2f" (customShape.Describe()) (customShape.Area())

        // 3. Type Extension in action
        let sample = "functional programming in f#"
        printfn "Original: '%s' | TitleCase: '%s'" sample (sample.ToTitleCase())
