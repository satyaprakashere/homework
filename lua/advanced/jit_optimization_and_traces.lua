-- ==============================================================================
-- advanced/jit_optimization_and_traces.lua: JIT Introspection & Benchmarking
-- Compatible with: LuaJIT
-- Run with: luajit advanced/jit_optimization_and_traces.lua
-- ==============================================================================

-- LuaJIT is a tracing JIT compiler. It begins by interpreting bytecode.
-- When a loop or function becomes "hot" (executed many times), LuaJIT compiles
-- the linear execution trace directly into optimized machine code (x86_64, ARM64, etc.).

print("=== 1. JIT Version and State ===")
print("Lua Version:   ", _VERSION)
print("LuaJIT Version:", jit.version)
print("Target Arch:   ", jit.arch)
print("OS:            ", jit.os)

-- jit.status() returns boolean (active/inactive) and active optimization flags
local jit_active, opt1, opt2 = jit.status()
print("JIT active:    ", jit_active, opt1 or "", opt2 or "")

print("\n=== 2. Tracing the JIT Compiler in Action (jit.v) ===")
-- LuaJIT includes built-in diagnostic modules: 'jit.v' (verbose) and 'jit.dump'.
-- 'jit.v' outputs a log line whenever LuaJIT detects a hot loop, compiles a trace,
-- or aborts compilation due to a NYI (Not Yet Implemented) bytecode.

local jv_ok, jv = pcall(require, "jit.v")
if jv_ok then
    print("Activating jit.v trace logger...")
    jv.on()
end

-- Function with a hot loop that LuaJIT will compile into machine code:
local function compute_series(n)
    local sum = 0.0
    for i = 1, n do
        sum = sum + (1.0 / (i * i))
    end
    return sum
end

print("Running compute_series (watch for [TRACE ...] lines from jit.v):")
local series_result = compute_series(50000)
print(string.format("Series result ~= pi^2 / 6: %.6f", series_result))

if jv_ok then
    jv.off()
end

print("\n=== 3. Performance Notes: Assembly Interpreter vs JIT Traces ===")
-- Key takeaway about LuaJIT performance:
-- 1. LuaJIT's INTERPRETER is not like standard Lua: it is written entirely in
--    hand-crafted assembly code for the target CPU (ARM64 / x86_64).
-- 2. LuaJIT's TRACE COMPILER compiles linear hot loops into machine code,
--    eliminating bounds checks, boxing, and opcode dispatch overhead.
-- 3. In both modes, LuaJIT is typically 10x-50x faster than standard PUC-Lua 5.1.

print("\n=== 4. LuaJIT NYI (Not Yet Implemented) & Trace Aborts ===")
-- In LuaJIT, some operations cannot be compiled into traces and cause "trace aborts",
-- forcing LuaJIT back into interpreted mode for that path.
-- Common NYI pitfalls to avoid in performance-critical hot loops:
--   1. Calling C-functions not declared via FFI (Lua C API functions)
--   2. Modifying table metatables inside loops
--   3. Deep or unrolled recursion instead of iteration
--   4. Standard io / file operations directly in the inner loop

print("Performance Rules of Thumb for LuaJIT:")
print("  * Prefer numeric 'for i = 1, n do' or FFI arrays for inner loops.")
print("  * Pre-allocate table sizes if possible, or use FFI structs for high-volume data.")
print("  * Use LuaJIT FFI instead of classic C modules for near-zero call overhead.")
print("  * Avoid creating temporary closures or tables inside ultra-hot inner loops.")

print("\n[OK] advanced/jit_optimization_and_traces.lua completed successfully.")
