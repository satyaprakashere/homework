/**
 * Maximum safe integer limit used for wrapping logic.
 * @constant {number}
 */
const MAX_SAFE = (Number.MAX_SAFE_INTEGER-1) / 2
/**
 * 32-bit signed integer maximum limit used for bitwise operations.
 * @constant {number}
 */
const INT32_MAX = (2147483647 - 1) / 2

/**
 * Computes the n-th Fibonacci number.
 * 
 * @param {number} n - The position in the Fibonacci sequence.
 * @returns {number} The n-th Fibonacci number.
 */
function fibonacci(n) {
    return fibH(n)
}

/**
 * Helper function to compute Fibonacci recursively with tail recursion logic.
 * 
 * @param {number} n - The number of remaining iterations.
 * @param {number} [a=0] - The current Fibonacci number.
 * @param {number} [b=1] - The next Fibonacci number.
 * @returns {number} The computed Fibonacci number.
 */
function fibH(n, a = 0, b = 1) {
    if (n == 0) {
        return a;
    }
    return fibH(n-1, b, (a+b) % MAX_SAFE);
}


console.log(fibonacci(98765432));
