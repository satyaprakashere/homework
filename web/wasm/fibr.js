function fibonacci(n) {
    return fibH(n)
}

function fibH(n, a = 0, b = 1) {
    if (n == 0) {
        return a;
    }
    return fibH(n-1, b, a+b >>> 0);
}
    
    
console.log(fibonacci(98765432)); // Output: 55
    