-- ==============================================================================
-- functions.lua: Functions, Closures, and Functional Patterns
-- Compatible with: LuaJIT
-- Run with: luajit functions.lua
-- ==============================================================================

print("=== 1. Basic Functions & First-Class Values ===")

-- Standard function declaration
local function add(a, b)
    return a + b
end

-- Functions are first-class values (can be stored in variables, passed, returned)
local subtract = function(a, b)
    return a - b
end

local operations = {
    ["+"] = add,
    ["-"] = subtract,
    ["*"] = function(a, b) return a * b end,
}

print("5 + 3 =", operations["+"](5, 3))
print("5 * 3 =", operations["*"](5, 3))

print("\n=== 2. Multiple Return Values ===")
-- Lua natively supports multiple return values from functions
local function min_max(numbers)
    if #numbers == 0 then return nil, nil end
    local min_val = numbers[1]
    local max_val = numbers[1]
    for i = 2, #numbers do
        local v = numbers[i]
        if v < min_val then min_val = v end
        if v > max_val then max_val = v end
    end
    return min_val, max_val
end

local low, high = min_max({ 42, 7, 19, 99, 3, 55 })
print("Min:", low, "Max:", high)

print("\n=== 3. Variadic Functions (...) and select() ===")
-- The '...' syntax captures variable number of arguments
local function sum_all(...)
    local total = 0
    -- select('#', ...) returns the count of arguments
    local count = select('#', ...)
    for i = 1, count do
        -- select(i, ...) returns the i-th argument and all subsequent ones
        local val = select(i, ...)
        total = total + val
    end
    return total, count
end

local total, count = sum_all(10, 20, 30, 40)
print("Total of", count, "numbers is:", total)

print("\n=== 4. Closures and State Encapsulation ===")
-- Functions can capture variables from enclosing scopes (upvalues).
-- This allows building private state without classes or global variables.
local function create_counter(start_value)
    local count = start_value or 0
    return {
        increment = function(step)
            step = step or 1
            count = count + step
            return count
        end,
        decrement = function(step)
            step = step or 1
            count = count - step
            return count
        end,
        get = function()
            return count
        end
    }
end

local counterA = create_counter(100)
local counterB = create_counter(0)

print("counterA increment:", counterA.increment(5)) -- 105
print("counterB increment:", counterB.increment(1)) -- 1
print("counterA get:", counterA.get())             -- 105 (independent state)

print("\n=== 5. Proper Tail Call Optimization ===")
-- Lua performs tail-call elimination. Returning the result of another function directly:
-- 'return func(args)' does not consume stack frames! This allows infinite recursion.
local function countdown_tail(n, acc)
    acc = acc or 0
    if n <= 0 then
        return acc
    end
    -- Tail call: nothing else happens after the function call
    return countdown_tail(n - 1, acc + 1)
end

print("Tail call with 100,000 steps:", countdown_tail(100000))

print("\n=== 6. Higher-Order Functions: map, filter, reduce ===")
local function map(list, fn)
    local result = {}
    for i, v in ipairs(list) do
        result[i] = fn(v, i)
    end
    return result
end

local function filter(list, predicate)
    local result = {}
    for _, v in ipairs(list) do
        if predicate(v) then
            result[#result + 1] = v
        end
    end
    return result
end

local function reduce(list, fn, initial)
    local acc = initial
    for _, v in ipairs(list) do
        acc = fn(acc, v)
    end
    return acc
end

local nums = { 1, 2, 3, 4, 5, 6 }
local doubled = map(nums, function(x) return x * 2 end)
local evens = filter(doubled, function(x) return x % 4 == 0 end)
local sum = reduce(evens, function(acc, x) return acc + x end, 0)

print("Doubled:", table.concat(doubled, ", "))
print("Divisible by 4:", table.concat(evens, ", "))
print("Sum:", sum)

print("\n[OK] functions.lua completed successfully.")
