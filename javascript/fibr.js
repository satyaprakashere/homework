const MAX_SAFE = (Number.MAX_SAFE_INTEGER-1) / 2
const INT32_MAX = (2147483647 - 1) / 2

function fibonacci(n) {
    return fibH(n)
}

function fibH(n, a = 0, b = 1) {
    if (n == 0) {
        return a;
    }
    return fibH(n-1, b, (a+b) & INT32_MAX);
}

console.log(fibonacci(987654321)); // Output: 55