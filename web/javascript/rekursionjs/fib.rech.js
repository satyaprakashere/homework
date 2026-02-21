function fibonacci n do
    if n <= 1 do return(n)
    
    let mutable prev = 0, curr = 1 in
    forLoop (let i = 2, until i <= n, step i++) do
        let next = (prev + curr) >>> 0
        prev = curr
        curr = next
    end
    
    return(curr)
end

console.log(fibonacci(98765432)); // Output: 55