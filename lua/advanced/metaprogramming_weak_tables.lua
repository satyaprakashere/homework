-- ==============================================================================
-- advanced/metaprogramming_weak_tables.lua: Advanced Metaprogramming & Weak Tables
-- Compatible with: LuaJIT
-- Run with: luajit advanced/metaprogramming_weak_tables.lua
-- ==============================================================================

print("=== 1. Read-Only Tables (Immutability Pattern) ===")
-- By keeping the original table private and routing all operations through
-- an empty proxy table, we can prevent unauthorized modifications.

local function make_readonly(source_table)
    local proxy = {}
    local mt = {
        __index = source_table,
        __newindex = function(_, key, _)
            error(string.format("Attempt to modify read-only table key '%s'", tostring(key)), 2)
        end,
        __pairs = function()
            return pairs(source_table)
        end,
        __tostring = function()
            return "[ReadOnly Table]"
        end
    }
    return setmetatable(proxy, mt)
end

local settings = make_readonly({ host = "api.service.internal", port = 443 })
print("Read allowed: settings.host =", settings.host)

local ok, err = pcall(function()
    settings.port = 8080 -- this should fail
end)
print("Write blocked:", not ok)
print("Error captured:", err)

print("\n=== 2. Autovivification (Automatic Nested Table Creation) ===")
-- Like defaultdict in Python or autovivification in Perl, accessing a missing key
-- automatically instantiates a new nested table.

local function auto_table()
    return setmetatable({}, {
        __index = function(tbl, key)
            local new_sub = auto_table()
            rawset(tbl, key, new_sub) -- use rawset to avoid triggering __newindex
            return new_sub
        end
    })
end

local tree = auto_table()
-- Assign directly into deep nonexistent paths without checking each level:
tree.users.admins["001"].name = "Root Administrator"
tree.users.admins["001"].active = true

print("Deep access: tree.users.admins['001'].name =>", tree.users.admins["001"].name)
print("Deep access: tree.users.admins['001'].active =>", tree.users.admins["001"].active)

print("\n=== 3. Weak Tables and Non-Leaking Memoization ===")
-- Normally, storing objects in a table prevents the Lua Garbage Collector
-- from ever collecting them. Weak tables (__mode = "k", "v", or "kv") solve this!
-- "k": keys are weak (if no other reference to key exists, entry is collected)
-- "v": values are weak (if no other reference to value exists, entry is collected)

local function memoize_weak(computation_fn)
    local cache = setmetatable({}, { __mode = "k" }) -- weak keys
    return function(obj)
        if cache[obj] == nil then
            cache[obj] = computation_fn(obj)
        end
        return cache[obj]
    end
end

-- Function computing hash or metadata for complex table objects
local compute_metadata = memoize_weak(function(tbl)
    print("  [Heavy computation triggered for object]")
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return { field_count = count, generated_at = os.time() }
end)

do
    local item = { name = "Widget", price = 19.99, sku = "W123" }
    print("First call (computes):")
    local meta1 = compute_metadata(item)
    print("  Field count:", meta1.field_count)

    print("Second call (cached):")
    local meta2 = compute_metadata(item)
    print("  Same cached instance?", meta1 == meta2)
    -- 'item' goes out of scope here
end

-- When 'item' is collected, its entry in cache will be cleaned automatically!
collectgarbage("collect")
print("Weak table test completed without memory leaks.")

print("\n=== 4. Full Access Interception (Proxy Logger) ===")
-- Intercepting all get and set operations on an existing table
local function make_traced(name, target)
    local storage = target
    local proxy = {}
    setmetatable(proxy, {
        __index = function(_, k)
            print(string.format("  [TRACE %s] GET '%s' => '%s'", name, tostring(k), tostring(storage[k])))
            return storage[k]
        end,
        __newindex = function(_, k, v)
            print(string.format("  [TRACE %s] SET '%s' = '%s'", name, tostring(k), tostring(v)))
            storage[k] = v
        end
    })
    return proxy
end

local account = make_traced("Account", { balance = 1000 })
account.balance = account.balance + 500

print("\n[OK] advanced/metaprogramming_weak_tables.lua completed successfully.")
