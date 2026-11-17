-- ==============================================================================
-- fibonacci.lua: Linear O(n) and Logarithmic O(log n) Fibonacci Algorithms
-- Compatible with: LuaJIT (leverages 64-bit ULL integers and the 'bit' module)
-- Run with: luajit fibonacci.lua
-- ==============================================================================

local bit = require("bit")

print("=================================================================")
print(" Fibonacci Algorithms: Linear O(n) vs Logarithmic O(log n)")
print("=================================================================")

-- ------------------------------------------------------------------------------
-- 1. O(n) Linear Iterative Fibonacci
-- ------------------------------------------------------------------------------
-- State tracking with two variables. Time complexity: O(n), Space: O(1).
local function fib_linear_iterative(n)
    if n == 0 then return 0ULL end
    if n == 1 then return 1ULL end

    local a = 0ULL
    local b = 1ULL
    for _ = 2, n do
        local c = a + b
        a = b
        b = c
    end
    return b
end

-- ------------------------------------------------------------------------------
-- 2. O(n) Linear Tail-Recursive Fibonacci
-- ------------------------------------------------------------------------------
-- Exploits Lua's proper tail call elimination. Time: O(n), Stack Space: O(1).
local function fib_linear_tail(n, a, b)
    a = a or 0ULL
    b = b or 1ULL
    if n == 0 then return a end
    if n == 1 then return b end
    return fib_linear_tail(n - 1, b, a + b)
end

-- ------------------------------------------------------------------------------
-- 3. O(log n) Fast Doubling Fibonacci
-- ------------------------------------------------------------------------------
-- Based on the identity:
--   F(2k)   = F(k) * (2 * F(k+1) - F(k))
--   F(2k+1) = F(k+1)^2 + F(k)^2
-- Computes the pair (F(n), F(n+1)) in O(log n) steps.
local function fast_doubling(n)
    if n == 0 then
        return 0ULL, 1ULL
    end

    local a, b = fast_doubling(bit.rshift(n, 1)) -- n // 2
    local c = a * (2ULL * b - a)
    local d = a * a + b * b

    if bit.band(n, 1) == 0 then
        return c, d
    else
        return d, c + d
    end
end

local function fib_log_doubling(n)
    local fn, _ = fast_doubling(n)
    return fn
end

-- ------------------------------------------------------------------------------
-- 4. O(log n) Matrix Exponentiation Fibonacci
-- ------------------------------------------------------------------------------
-- [ F(n+1)  F(n)   ] = [ 1  1 ]^n
-- [ F(n)    F(n-1) ]   [ 1  0 ]
-- Using binary exponentiation (repeated squaring).

local function matrix_mult_2x2(A, B)
    return {
        A[1] * B[1] + A[2] * B[3],  A[1] * B[2] + A[2] * B[4],
        A[3] * B[1] + A[4] * B[3],  A[3] * B[2] + A[4] * B[4]
    }
end

local function matrix_pow_2x2(M, p)
    -- Identity matrix
    local result = { 1ULL, 0ULL, 0ULL, 1ULL }
    local base = { M[1], M[2], M[3], M[4] }

    while p > 0 do
        if bit.band(p, 1) == 1 then
            result = matrix_mult_2x2(result, base)
        end
        base = matrix_mult_2x2(base, base)
        p = bit.rshift(p, 1)
    end
    return result
end

local function fib_log_matrix(n)
    if n == 0 then return 0ULL end
    local T = { 1ULL, 1ULL, 1ULL, 0ULL }
    local res = matrix_pow_2x2(T, n - 1)
    return res[1] -- F(n)
end

-- ------------------------------------------------------------------------------
-- 5. O(log n) Modular Fibonacci for Astronomical n (e.g. n = 1,000,000,000)
-- ------------------------------------------------------------------------------
-- When n is huge (e.g., 10^9), linear O(n) takes seconds and 10^9 loop iterations.
-- O(log n) solves F(1,000,000,000) mod (10^9 + 7) in merely ~30 multiplications!

local MOD = 1000000007ULL

local function matrix_mult_mod(A, B, m)
    return {
        (A[1] * B[1] + A[2] * B[3]) % m, (A[1] * B[2] + A[2] * B[4]) % m,
        (A[3] * B[1] + A[4] * B[3]) % m, (A[3] * B[2] + A[4] * B[4]) % m
    }
end

local function fib_huge_modulo(n, m)
    if n == 0 then return 0ULL end
    local result = { 1ULL, 0ULL, 0ULL, 1ULL }
    local base = { 1ULL, 1ULL, 1ULL, 0ULL }
    local p = n - 1

    while p > 0 do
        if bit.band(p, 1) == 1 then
            result = matrix_mult_mod(result, base, m)
        end
        base = matrix_mult_mod(base, base, m)
        p = bit.rshift(p, 1)
    end
    return result[1]
end

-- ==============================================================================
-- Verification & Testing
-- ==============================================================================
print("\n--- Verifying Correctness for First 15 Fibonacci Numbers ---")
print(string.format("%-4s | %-12s | %-12s | %-12s", "n", "Linear Iter", "Log Doubling", "Log Matrix"))
print(string.rep("-", 48))

for i = 0, 15 do
    local f_iter = fib_linear_iterative(i)
    local f_doub = fib_log_doubling(i)
    local f_mat  = fib_log_matrix(i)
    print(string.format("%-4d | %-12s | %-12s | %-12s", i, tostring(f_iter), tostring(f_doub), tostring(f_mat)))
    assert(f_iter == f_doub and f_doub == f_mat, "Mismatch in results!")
end

print("\n--- Testing Large 64-bit Fibonacci Values (up to F(93)) ---")
-- F(93) is 12200160415121876738ULL, the largest Fibonacci number fitting in uint64_t
local test_indices = { 20, 40, 60, 80, 93 }
for _, idx in ipairs(test_indices) do
    local f_lin = fib_linear_iterative(idx)
    local f_log = fib_log_doubling(idx)
    print(string.format("F(%2d) = %s (matches: %s)", idx, tostring(f_log), tostring(f_lin == f_log)))
end

print("\n--- Astronomical Input: F(1,000,000,000) modulo (10^9 + 7) ---")
local huge_n = 1000000000
local t0 = os.clock()
local huge_res = fib_huge_modulo(huge_n, MOD)
local t_huge = os.clock() - t0
print(string.format("F(10^9) mod %s = %s", tostring(MOD), tostring(huge_res)))
print(string.format("Calculated in: %.6f seconds (30 matrix multiplications!)", t_huge))

print("\n--- Benchmark: O(n) Linear vs O(log n) Fast Doubling ---")
local bench_n = 90
local reps = 500000

t0 = os.clock()
for _ = 1, reps do
    fib_linear_iterative(bench_n)
end
local t_linear = os.clock() - t0

t0 = os.clock()
for _ = 1, reps do
    fib_log_doubling(bench_n)
end
local t_log = os.clock() - t0

print(string.format("Calculating F(%d) x %d times:", bench_n, reps))
print(string.format("  Linear O(n) Iterative:  %.4f seconds", t_linear))
print(string.format("  Logarithmic O(log n):   %.4f seconds", t_log))
if t_log > 0 then
    print(string.format("  Logarithmic speedup:    %.2fx", t_linear / t_log))
end

print("\n[OK] fibonacci.lua completed successfully.")
