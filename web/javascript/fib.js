/**
 * Calculates the nth Fibonacci number with maximum performance.
 * @param {number} n - The index of the Fibonacci sequence.
 * @returns {BigInt} - The Fibonacci number at index n.
 */
"use strict";

function fastFibonacci(n) {
  if (n <= 0) return 0n;
  if (n === 1) return 1n;

  let prev = 0, curr = 1;
  for (let i = 2; i <= n; i++) {
    const next = (prev + curr) >>> 0;
    prev = curr;
    curr = next;
  }
  return curr;
}

console.log(fastFibonacci(10));
console.log(fastFibonacci(98765432));
