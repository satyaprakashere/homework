-- ==============================================================================
-- basics.lua: Lua Basics & Core Types
-- Compatible with: LuaJIT (Lua 5.1 + LuaJIT extensions)
-- Run with: luajit basics.lua
-- ==============================================================================

print("=== 1. Basic Output and Comments ===")
-- Single line comment starts with double dash
--[[
  Multi-line comment starts with --[[ and ends with ]]
--]]
print("Hello, LuaJIT!")

print("\n=== 2. Primitive Data Types ===")
-- Lua has 8 basic types: nil, boolean, number, string, table, function, thread, userdata
local a_nil = nil
local a_bool = true
local a_num_int = 42
local a_num_float = 3.14159
local a_str = "Lua is elegant"
local a_tbl = { 10, 20, 30 }
local a_func = function() return "I am a function" end

print("type(a_nil):", type(a_nil))
print("type(a_bool):", type(a_bool))
print("type(a_num_int):", type(a_num_int))
print("type(a_num_float):", type(a_num_float))
print("type(a_str):", type(a_str))
print("type(a_tbl):", type(a_tbl))
print("type(a_func):", type(a_func))

print("\n=== 3. Scope: Local vs Global ===")
-- Always prefer 'local' variables for better performance and encapsulation.
-- In LuaJIT, local variables are stored in CPU registers / fast stack slots.
local local_var = "I am private to this scope"
global_var = "I am in the global environment _G"

print("local_var:", local_var)
print("global_var:", _G["global_var"])

do
    local inner_scope = "Visible only inside 'do ... end'"
    print("Inside block:", inner_scope)
end
-- inner_scope is nil here

print("\n=== 4. Truthiness and Conditionals ===")
-- In Lua, ONLY 'false' and 'nil' are falsey!
-- 0, empty string "", and empty table {} are ALL TRUTHY!
local zero = 0
local empty_str = ""
if zero and empty_str then
    print("NOTE: In Lua, both 0 and \"\" evaluate to TRUE!")
end

local score = 85
if score >= 90 then
    print("Grade: A")
elseif score >= 80 then
    print("Grade: B")
else
    print("Grade: C or below")
end

-- Ternary operator pattern: (cond and truthy_val or falsy_val)
-- Note: only safe if truthy_val is never false/nil.
local is_admin = true
local role = is_admin and "Administrator" or "Standard User"
print("User role:", role)

print("\n=== 5. Loops ===")

-- 5a. While loop
print("-- While Loop --")
local count = 1
while count <= 3 do
    print("while count:", count)
    count = count + 1
end

-- 5b. Repeat-until loop (executes at least once; test is at the end)
print("-- Repeat-Until Loop --")
local r = 3
repeat
    print("repeat r:", r)
    r = r - 1
until r == 0

-- 5c. Numeric for loop: for var = start, stop, step do
print("-- Numeric For Loop --")
for i = 1, 5, 2 do
    print("for step 2:", i)
end

-- Reverse numeric for loop
for i = 3, 1, -1 do
    print("for countdown:", i)
end

-- 5d. Break statement
print("-- Break statement --")
for i = 1, 10 do
    if i > 2 then
        print("breaking at", i)
        break
    end
end

print("\n=== 6. LuaJIT Goto and Labels (Lua 5.2+ extension in LuaJIT) ===")
-- LuaJIT supports 'goto' and '::label::'
local step = 1
::retry::
if step <= 2 then
    print("Executing goto loop step:", step)
    step = step + 1
    goto retry
end

print("\n[OK] basics.lua completed successfully.")
