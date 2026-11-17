const MAX_SAFE = (Number.MAX_SAFE_INTEGER-1) / 2 + 1
//const INT32_MAX = (2147483647 - 1) / 2

function fibonacci(n) {
    return fastFibonacci(n)
}

function fastFibonacci(n) {
//  if (n <= 0) return 0n;
    if (n === 1) return 1n;
    
    let a = 0; // n-2
    let b = 1; // n-1
    
    for (let i = 2; i <= n; i++) {
        // High-speed swap and addition
        const temp = (a + b) % MAX_SAFE;
        a = b;
        b = temp;
    }
    
    return b;
}


console.log(fibonacci(987654321));