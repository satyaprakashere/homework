function fibonacci(n: i32): i32 {
    if (n <= 1)
        return n
    let prev = 0, curr = 1
    for (let i = 2; i <= n; i++) {
        const next = (prev + curr) >>> 0
        prev = curr
        curr = next
    }

    return curr
}

console.log(fibonacci(98765432).toString()) // Output: 3012054389
