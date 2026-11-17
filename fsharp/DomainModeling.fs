namespace FSharpLearning

module DomainModeling =

    // Record types
    type Address = {
        Street: string
        City: string
        PostalCode: string
    }

    type User = {
        Id: int
        Name: string
        Email: string
        Address: Address
        IsAdmin: bool
    }

    // Discriminated Unions (Sum types)
    type PaymentMethod =
        | Cash
        | CreditCard of cardNumber: string * expiry: string
        | PayPal of email: string
        | Crypto of walletAddress: string

    // Single-case Discriminated Unions (Strongly typed IDs preventing primitive obsession)
    type CustomerId = CustomerId of int
    type OrderId = OrderId of int

    // Recursive Discriminated Union
    type BinaryTree<'T> =
        | Leaf of 'T
        | Node of BinaryTree<'T> * 'T * BinaryTree<'T>

    // Domain State Machine: Making Invalid States Impossible
    type UnvalidatedOrder = { Items: string list; CustomerEmail: string }
    type ValidatedOrder = { Items: string list; CustomerEmail: string; TotalAmount: decimal }
    type PaidOrder = { Validated: ValidatedOrder; TransactionId: string }
    type ShippedOrder = { Paid: PaidOrder; TrackingNumber: string }

    type OrderWorkflowState =
        | Unvalidated of UnvalidatedOrder
        | Validated of ValidatedOrder
        | Paid of PaidOrder
        | Shipped of ShippedOrder

    let run () =
        printfn "\n=================================================="
        printfn ">>> MODULE: Domain Modeling & Types"
        printfn "=================================================="

        // 1. Tuples
        let coordinates = (45.5231, -122.6765)
        let (lat, lon) = coordinates
        printfn "Tuple coordinates: Lat=%.4f, Lon=%.4f" lat lon

        // 2. Records & Structural Equality
        let user1 = {
            Id = 1
            Name = "Alice"
            Email = "alice@example.com"
            Address = { Street = "100 Main St"; City = "Springfield"; PostalCode = "12345" }
            IsAdmin = false
        }

        let user2 = {
            Id = 1
            Name = "Alice"
            Email = "alice@example.com"
            Address = { Street = "100 Main St"; City = "Springfield"; PostalCode = "12345" }
            IsAdmin = false
        }

        printfn "Structural equality (user1 = user2): %b" (user1 = user2)

        // Non-destructive copy-and-update using 'with'
        let promotedUser = { user1 with IsAdmin = true }
        printfn "Original Admin: %b, Promoted Admin: %b" user1.IsAdmin promotedUser.IsAdmin

        // 3. Discriminated Unions
        let payWithMethod payment amount =
            match payment with
            | Cash -> 
                printfn "Paid $%.2f in Cash." amount
            | CreditCard (cardNum, exp) -> 
                printfn "Paid $%.2f with Card ending in %s (Exp: %s)." amount (cardNum.Substring(cardNum.Length - 4)) exp
            | PayPal email -> 
                printfn "Paid $%.2f via PayPal (%s)." amount email
            | Crypto wallet -> 
                printfn "Paid $%.2f via Crypto wallet %s." amount wallet

        payWithMethod Cash 12.50
        payWithMethod (CreditCard ("4111111111119999", "12/28")) 89.99
        payWithMethod (PayPal "alice@example.com") 45.00

        // 4. Single-Case Discriminated Unions
        let processOrder (CustomerId custId) (OrderId ordId) =
            printfn "Processing order #%d for customer #%d" ordId custId

        let cId = CustomerId 101
        let oId = OrderId 5001
        processOrder cId oId

        // 5. Recursive Discriminated Unions (Tree)
        let myTree = 
            Node(
                Node(Leaf 1, 2, Leaf 3),
                4,
                Node(Leaf 5, 6, Leaf 7)
            )

        let rec sumTree tree =
            match tree with
            | Leaf value -> value
            | Node (left, value, right) -> (sumTree left) + value + (sumTree right)

        printfn "Sum of binary tree nodes: %d" (sumTree myTree)

        // 6. State Machine Pattern
        let describeState orderState =
            match orderState with
            | Unvalidated u -> $"Order pending validation for {u.CustomerEmail} with {u.Items.Length} items"
            | Validated v -> $"Order validated for {v.CustomerEmail}, total: ${v.TotalAmount}"
            | Paid p -> $"Order paid! Txn: {p.TransactionId}"
            | Shipped s -> $"Order shipped with tracking #{s.TrackingNumber}"

        let pendingOrder = Unvalidated { Items = ["Keyboard"; "Mouse"]; CustomerEmail = "bob@example.com" }
        printfn "Order status: %s" (describeState pendingOrder)
