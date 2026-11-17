-- ==============================================================================
-- coroutines.lua: Coroutines & Cooperative Multitasking
-- Compatible with: LuaJIT
-- Run with: luajit coroutines.lua
-- ==============================================================================

print("=== 1. Basic Coroutine Lifecycle ===")
-- Unlike OS threads, Lua coroutines are non-preemptive / cooperative.
-- Execution only yields when explicitly instructed by coroutine.yield().

local co = coroutine.create(function(initial_val)
    print("  [co] started with:", initial_val)
    local y_res = coroutine.yield("first pause")
    print("  [co] resumed with:", y_res)
    return "done final result"
end)

print("Status initially:", coroutine.status(co)) -- suspended

-- 1st resume starts the coroutine
local ok, result = coroutine.resume(co, "init data")
print("1st resume returned:", ok, result)
print("Status while yielded:", coroutine.status(co)) -- suspended

-- 2nd resume passes value back to the yield() call inside co
ok, result = coroutine.resume(co, "resumed data")
print("2nd resume returned:", ok, result)
print("Status after completion:", coroutine.status(co)) -- dead

print("\n=== 2. Coroutine as Generator with coroutine.wrap ===")
-- coroutine.wrap creates a function that automatically calls coroutine.resume.
-- When called, it yields the next value, making it perfect for custom iterators!

local function range_generator(start_val, end_val, step)
    step = step or 1
    return coroutine.wrap(function()
        local current = start_val
        while current <= end_val do
            coroutine.yield(current)
            current = current + step
        end
    end)
end

print("Iterating with generator:")
for val in range_generator(10, 50, 10) do
    print("  yielded value:", val)
end

print("\n=== 3. Producer-Filter-Consumer Pipeline ===")
-- Coroutines make building streaming data pipelines clean and decoupled.

local function producer(items)
    return coroutine.create(function()
        for _, item in ipairs(items) do
            print(string.format("  [Producer] produced item: %s", item))
            coroutine.yield(item)
        end
    end)
end

local function filter_pipeline(source_co, transform_fn)
    return coroutine.create(function()
        while coroutine.status(source_co) ~= "dead" do
            local ok, item = coroutine.resume(source_co)
            if ok and item ~= nil then
                local transformed = transform_fn(item)
                print(string.format("  [Filter] transformed '%s' -> '%s'", item, transformed))
                coroutine.yield(transformed)
            end
        end
    end)
end

local raw_data = { "apple", "banana", "kiwi", "mango" }
local prod = producer(raw_data)
local upper_filter = filter_pipeline(prod, string.upper)

-- Consumer loop
print("Consuming items:")
while coroutine.status(upper_filter) ~= "dead" do
    local ok, item = coroutine.resume(upper_filter)
    if ok and item ~= nil then
        print(string.format("  [Consumer] Received final: %s", item))
    end
end

print("\n[OK] coroutines.lua completed successfully.")
