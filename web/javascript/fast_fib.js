/**
 * Computes the n-th Fibonacci number using a typed array for 32-bit wrapping.
 *
 * @param {number} n - The position in the Fibonacci sequence.
 * @returns {number} The n-th Fibonacci number wrapped to 32 bits.
 */
function fib32Wrap(n) {
  // We use a size-2 array as our "registers"
  const reg = new Uint32Array(2);
  reg[0] = 0; // F(n-2)
  reg[1] = 1; // F(n-1)

  if (n < 2) return n;

  for (let i = 2; i <= n; i++) {
    const next = reg[0] + reg[1];
    reg[0] = reg[1];
    reg[1] = next; // The Typed Array handles the 32-bit wrap automatically
  }

  return reg[1];
}

console.log(fib32Wrap(987654321));