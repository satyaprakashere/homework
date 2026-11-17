fun fib (num: UInt) : ULong {
    tailrec fun fibH(n: UInt, a: ULong, b: ULong) : ULong {
        return if (n == 0u) a
            else fibH(n - 1u, b, a + b)
    }
    return fibH(num, 0u, 1u)
}

fun main() {
    println(fib(987654321u))
}
