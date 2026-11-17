-- ==============================================================================
-- advanced/ffi_c_interop.lua: LuaJIT Foreign Function Interface (FFI)
-- Compatible with: LuaJIT
-- Run with: luajit advanced/ffi_c_interop.lua
-- ==============================================================================

-- LuaJIT's FFI library lets you call external C functions and use C data
-- structures directly from Lua code WITHOUT writing C wrapper code or compiling!

local ffi = require("ffi")

print("=== 1. Declaring and Calling Standard C Library Functions ===")
-- Use ffi.cdef to declare standard C signatures
ffi.cdef[[
    int getpid(void);
    unsigned int sleep(unsigned int seconds);
    double sin(double x);
    double cos(double x);
    double sqrt(double x);
    int puts(const char *s);
]]

-- ffi.C gives direct access to the default C library symbols
local pid = ffi.C.getpid()
print("Current Process ID from libc getpid():", pid)

local val = 45.0 * (math.pi / 180.0)
print("sin(45 deg) from libc:", ffi.C.sin(val))
print("sqrt(144) from libc:  ", ffi.C.sqrt(144.0))

print("\n=== 2. C Callbacks: Calling Lua from C ===")
-- Many C functions (like qsort) accept function pointers (callbacks).
-- LuaJIT FFI lets you pass a Lua function directly as a C callback!

ffi.cdef[[
    typedef int (*qsort_cmp)(const void *, const void *);
    void qsort(void *base, size_t nel, size_t width, qsort_cmp compar);
]]

-- Allocate a C int32_t array of 6 elements
local count = 6
local numbers = ffi.new("int32_t[?]", count, { 85, 12, 43, 99, 1, 37 })

print("Before qsort:")
local before_str = {}
for i = 0, count - 1 do
    table.insert(before_str, tostring(numbers[i]))
end
print(" ", table.concat(before_str, ", "))

-- Define the C comparison callback in Lua
local cmp_callback = ffi.cast("qsort_cmp", function(a, b)
    local pa = ffi.cast("const int32_t *", a)
    local pb = ffi.cast("const int32_t *", b)
    if pa[0] < pb[0] then return -1 end
    if pa[0] > pb[0] then return 1 end
    return 0
end)

-- Invoke C qsort with our Lua callback
ffi.C.qsort(numbers, count, ffi.sizeof("int32_t"), cmp_callback)

-- Free the callback handle when finished to release the JIT wrapper slot
cmp_callback:free()

print("After libc qsort:")
local after_str = {}
for i = 0, count - 1 do
    table.insert(after_str, tostring(numbers[i]))
end
print(" ", table.concat(after_str, ", "))

print("\n=== 3. C String Conversion ===")
-- Converting between Lua strings and C char pointers
local lua_str = "Hello through C char array!"
local c_str = ffi.new("char[?]", #lua_str + 1)
ffi.copy(c_str, lua_str)

-- ffi.string converts a C char pointer or array back into a native Lua string
local back_to_lua = ffi.string(c_str)
print("Converted back to Lua string:", back_to_lua)

print("\n[OK] advanced/ffi_c_interop.lua completed successfully.")
