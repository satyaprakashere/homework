function fibonacci n {
    if n <= 1 {
        return(n)
    }
    
    let mutable prev = 0, curr = 1
    forLoop (let i = 2, until i <= n, step i++) {
        let next = (prev + curr) >>> 0
        prev = curr
        curr = next
    }
    return(curr)
}

console.log(fibonacci(98765432)); // Output: 55