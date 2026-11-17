func fib(of n: UInt) -> UInt {
    func fibH(a: UInt, b: UInt, n: UInt) -> UInt {
        if n == 0 { return a }
        return fibH(a: b, b: a &+ b, n: n - 1)
    }
    return fibH(a: 0, b: 1, n: n)
}

// print("Fibonacci of 9876: \(fib of 9876)")
// print("Fibonacci of 9876: \(fib of: 9876)")
print("Fibonacci of 9876: \(fib(of: 9876))")
