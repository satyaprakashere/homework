-- ==============================================================================
-- strings_patterns.lua: String Manipulation & Lua Pattern Matching
-- Compatible with: LuaJIT
-- Run with: luajit strings_patterns.lua
-- ==============================================================================

print("=== 1. Basic String Operations ===")
-- Lua strings are immutable and 8-bit clean (can hold arbitrary binary data)
local str = "Hello, LuaJIT World!"
print("Length (#str):", #str)
print("Upper:", string.upper(str))
print("Lower:", string.lower(str))
print("Substring (8 to 13):", string.sub(str, 8, 13)) -- "LuaJIT"
print("Repeat:", string.rep("Lua!", 3))
print("Byte at index 1:", string.byte(str, 1))         -- ASCII code for 'H'
print("Char from byte 72:", string.char(72))          -- 'H'

-- String formatting (printf style)
local formatted = string.format("Name: %-10s | Score: %05d | Rate: %.2f%%", "Bob", 42, 98.7654)
print("Formatted:", formatted)

print("\n=== 2. Performance: '..' vs table.concat ===")
-- Repeated concatenation in a loop creates many intermediate strings.
-- Best practice: insert fragments into a table, then call table.concat.
local parts = {}
for i = 1, 5 do
    table.insert(parts, string.format("chunk%d", i))
end
local combined = table.concat(parts, " -> ")
print("Combined with table.concat:", combined)

print("\n=== 3. Lua Pattern Matching (Regex Alternative) ===")
-- Lua uses its own compact pattern matching instead of standard regex.
-- Pattern character classes:
--   %a = letters, %d = digits, %s = whitespace, %w = alphanumeric, %p = punctuation
--   Uppercase inverses: %A = non-letters, %D = non-digits, %S = non-whitespace
-- Modifiers:
--   + = 1 or more
--   * = 0 or more (greedy)
--   - = 0 or more (non-greedy / shortest match)
--   ? = 0 or 1

-- 3a. string.find: returns start and end positions
local text = "Order ID: ORD-2026-9812 status: SHIPPED"
local s_start, s_end = string.find(text, "ORD%-%d+%-%d+")
print("Found order ID from index", s_start, "to", s_end, ":", string.sub(text, s_start, s_end))

-- 3b. string.match: captures values with parentheses
local order_prefix, order_year, order_num = string.match(text, "(%a+)%-(%d+)%-(%d+)")
print("Captured prefix:", order_prefix, "year:", order_year, "number:", order_num)

-- 3c. Non-greedy modifier '-'
local html = "<div><b>First</b> and <b>Second</b></div>"
print("Greedy   .* :", string.match(html, "<b>.*</b>")) -- captures "<b>First</b> and <b>Second</b>"
print("Non-greedy .-: ", string.match(html, "<b>.-</b>")) -- captures "<b>First</b>"

-- 3d. string.gmatch: global iterator over all matches
print("\n-- Extracting all words from sentence with string.gmatch --")
local sentence = "Luajit is incredibly fast and lightweight"
for word in string.gmatch(sentence, "%a+") do
    print("  Word:", word)
end

-- Key-value parser using gmatch
print("\n-- Parsing key=value query string --")
local query = "user=prakash&lang=lua&role=admin"
local params = {}
for k, v in string.gmatch(query, "([^&=]+)=([^&=]+)") do
    params[k] = v
    print(string.format("  param: %s => %s", k, v))
end

-- 3e. string.gsub: Pattern substitution
-- Substitution can be a string, a table lookup, or a function callback!
local template = "Hello $name, your balance is $balance."
local values = { name = "Alice", balance = "$1,500" }

-- Function callback in gsub
local rendered = string.gsub(template, "%$(%w+)", function(key)
    return values[key] or ("<missing " .. key .. ">")
end)
print("\nTemplate substitution:", rendered)

-- Convert words to uppercase via function gsub
local uppercased = string.gsub("hello luajit world", "%a+", string.upper)
print("Words capitalized:", uppercased)

print("\n[OK] strings_patterns.lua completed successfully.")
