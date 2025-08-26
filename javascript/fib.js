function fibonacci(n) {
    if (n <= 1)
        return n;
    var prev = 0, curr = 1;
    for (var i = 2; i <= n; i++) {
        var next = (prev + curr) >>> 0;
        prev = curr;
        curr = next;
    }
    return curr;
}

console.log(fibonacci(98765432)); // Output: 55
