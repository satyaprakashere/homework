-- ==============================================================================
-- tables.lua: Tables, Arrays, Dictionaries, and the Table Standard Library
-- Compatible with: LuaJIT
-- Run with: luajit tables.lua
-- ==============================================================================

print("=== 1. Tables as Arrays (Sequences) ===")
-- Lua tables are 1-indexed by convention
local fruits = { "apple", "banana", "cherry" }

print("Length (#fruits):", #fruits)
print("fruits[1]:", fruits[1])
print("fruits[3]:", fruits[3])

-- Appending items
table.insert(fruits, "date")       -- inserts at end
table.insert(fruits, 2, "blueberry") -- inserts at index 2, shifts others
print("After inserts:", table.concat(fruits, ", "))

-- Removing items
local removed = table.remove(fruits, 2)
print("Removed:", removed)
print("After remove:", table.concat(fruits, ", "))

print("\n=== 2. Arrays: The 'Hole' Gotcha ===")
-- In Lua, an array sequence is valid up to the first nil.
-- If a table has nil values interspersed ("holes"), #t behavior is undefined!
local with_holes = { 10, 20, nil, 40 }
print("Array with holes #with_holes:", #with_holes, "(may not be 4!)")
-- Solution: store size explicitly or avoid nil holes in sequences.

print("\n=== 3. Tables as Dictionaries / Hashmaps ===")
local user = {
    username = "alice",
    age = 28,
    ["favorite-color"] = "cyan", -- bracket syntax for keys with dashes/spaces
    [100] = "numeric key",
}

print("user.username:", user.username)
print("user['age']:", user["age"])
print("user['favorite-color']:", user["favorite-color"])
print("user[100]:", user[100])

-- Setting/deleting keys
user.email = "alice@example.com" -- add key
user.age = nil                  -- setting a key to nil DELETES it from the table
print("user.age after delete:", user.age)

print("\n=== 4. Iteration: ipairs vs pairs ===")
-- ipairs: Iterates ONLY numeric sequential keys 1, 2, 3... Stops at first nil!
local tasks = { "write code", "test code", "deploy code" }
print("-- ipairs (ordered sequence) --")
for index, value in ipairs(tasks) do
    print(string.format("  Task #%d: %s", index, value))
end

-- pairs: Iterates ALL keys (in undefined/hash order)
print("-- pairs (all key-value pairs) --")
local config = { host = "127.0.0.1", port = 8080, debug = true, timeout = 30 }
for k, v in pairs(config) do
    print(string.format("  %s = %s", tostring(k), tostring(v)))
end

print("\n=== 5. Sorting Tables ===")
local scores = {
    { name = "Alice", score = 95 },
    { name = "Bob",   score = 72 },
    { name = "Carol", score = 88 },
}

-- Custom comparator: sorts in descending order of score
table.sort(scores, function(a, b)
    return a.score > b.score
end)

for i, entry in ipairs(scores) do
    print(string.format("  Rank %d: %s with %d pts", i, entry.name, entry.score))
end

print("\n=== 6. Tables as Sets ===")
-- To test membership in O(1) time, use table keys as set items
local function Set(list)
    local set = {}
    for _, item in ipairs(list) do
        set[item] = true
    end
    return set
end

local allowed_roles = Set({ "admin", "moderator", "editor" })
print("Is 'admin' allowed?", allowed_roles["admin"] ~= nil)
print("Is 'guest' allowed?", allowed_roles["guest"] ~= nil)

print("\n=== 7. Deep Copying Tables ===")
-- Tables in Lua are passed by reference, not by value!
local orig = { a = 1, b = { c = 2 } }
local ref = orig
ref.a = 99
print("orig.a changed via ref:", orig.a) -- 99

-- To clone independently:
local function deep_copy(obj, seen)
    if type(obj) ~= "table" then return obj end
    if seen and seen[obj] then return seen[obj] end

    local s = seen or {}
    local copy = {}
    s[obj] = copy
    for k, v in pairs(obj) do
        copy[deep_copy(k, s)] = deep_copy(v, s)
    end
    return copy
end

local cloned = deep_copy(orig)
cloned.b.c = 500
print("cloned.b.c:", cloned.b.c)
print("orig.b.c unchanged:", orig.b.c) -- 2

print("\n[OK] tables.lua completed successfully.")
