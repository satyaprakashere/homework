-- ==============================================================================
-- error_handling.lua: Errors, pcall, xpcall, and Stack Traces
-- Compatible with: LuaJIT
-- Run with: luajit error_handling.lua
-- ==============================================================================

print("=== 1. Assertions and Explicit Errors ===")
-- assert(cond, message) raises an error if cond is nil or false
local function divide(numerator, denominator)
    assert(type(numerator) == "number", "numerator must be a number")
    assert(type(denominator) == "number", "denominator must be a number")
    if denominator == 0 then
        -- error(message, [level]): level 2 blames the caller instead of divide itself
        error("Division by zero error", 2)
    end
    return numerator / denominator
end

print("10 / 2 =", divide(10, 2))

print("\n=== 2. Protected Calls with pcall (Try/Catch) ===")
-- pcall(func, arg1, arg2) runs func in protected mode.
-- Returns: true + return_values ON SUCCESS
-- Returns: false + error_message ON FAILURE
local success, result_or_err = pcall(divide, 10, 0)
if success then
    print("Result:", result_or_err)
else
    print("Caught error safely with pcall:")
    print("  ->", result_or_err)
end

print("\n=== 3. Extended Protected Calls with xpcall & Traceback ===")
-- xpcall(func, err_handler) allows capturing stack traces before unwinding.
local function faulty_operation(level)
    if level > 2 then
        error("Something went wrong deep inside call stack!")
    end
    faulty_operation(level + 1)
end

local function error_handler(err)
    -- debug.traceback generates a formatted stack trace
    local trace = debug.traceback(tostring(err), 2)
    return {
        message = tostring(err),
        stack_trace = trace,
        timestamp = os.time(),
    }
end

local ok, err_obj = xpcall(function()
    faulty_operation(1)
end, error_handler)

if not ok then
    print("Caught error object via xpcall:")
    print("  Message:", err_obj.message)
    print("  Traceback snippet:\n" .. string.sub(err_obj.stack_trace, 1, 300) .. "...")
end

print("\n=== 4. Try-Finally Pattern for Safe Resource Cleanup ===")
-- Lua lacks a built-in 'finally' keyword, but pcall can implement it reliably.
local function safe_execute(action_fn, cleanup_fn)
    local ok, res_or_err = pcall(action_fn)
    -- cleanup always runs whether action_fn succeeded or threw an error
    cleanup_fn()
    if not ok then
        error(res_or_err) -- rethrow if desired
    end
    return res_or_err
end

local file_open = true
local action_success, err = pcall(function()
    safe_execute(
        function()
            print("  [Action] Performing critical file processing...")
            error("Unexpected I/O failure!")
        end,
        function()
            file_open = false
            print("  [Cleanup] Closed open file handles safely!")
        end
    )
end)

print("Protected execution ended. File is open?", file_open)

print("\n[OK] error_handling.lua completed successfully.")
