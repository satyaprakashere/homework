-- ==============================================================================
-- advanced/ffi_memory_and_structs.lua: C Structs, Metatypes, and Memory Mgmt
-- Compatible with: LuaJIT
-- Run with: luajit advanced/ffi_memory_and_structs.lua
-- ==============================================================================

local ffi = require("ffi")

print("=== 1. Defining C Structs and ffi.metatype ===")
-- LuaJIT allows attaching Lua metamethods directly to C types using ffi.metatype!
-- This gives you C-struct memory layout and raw speed with friendly object-oriented syntax.

ffi.cdef[[
    typedef struct {
        double x;
        double y;
        double z;
    } point3d_t;
]]

-- Attach metamethods to 'point3d_t'
local Point3D = {}
Point3D.__index = Point3D

function Point3D:distance_to(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    local dz = self.z - other.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function Point3D:translate(dx, dy, dz)
    self.x = self.x + dx
    self.y = self.y + dy
    self.z = self.z + dz
end

Point3D.__tostring = function(p)
    return string.format("Point3D(%.2f, %.2f, %.2f)", p.x, p.y, p.z)
end

local point3d_ct = ffi.metatype("point3d_t", Point3D)

local p1 = point3d_ct(10.0, 20.0, 30.0)
local p2 = point3d_ct(13.0, 24.0, 30.0)

print("p1:", p1)
print("p2:", p2)
print("Distance between p1 and p2:", p1:distance_to(p2))

p1:translate(1.0, 1.0, 1.0)
print("p1 after translation:", p1)

print("\n=== 2. Struct Memory Layout and Sizes ===")
ffi.cdef[[
    typedef struct {
        uint8_t  flag;
        uint32_t id;
        double   timestamp;
    } packet_header_t;
]]

print("sizeof(packet_header_t):", ffi.sizeof("packet_header_t"), "bytes (includes C alignment padding)")
print("offsetof id:             ", ffi.offsetof("packet_header_t", "id"), "bytes")
print("offsetof timestamp:      ", ffi.offsetof("packet_header_t", "timestamp"), "bytes")

print("\n=== 3. 64-bit Integers (uint64_t / int64_t) ===")
-- Standard Lua 5.1 numbers are double-precision floats (53-bit integer precision).
-- LuaJIT adds native 64-bit integer support with 'LL' and 'ULL' literals!
local large_int = 0xFFFFFFFFFFFFFFFFULL
print("Max uint64_t:", large_int)
print("Arithmetic with 64-bit int:", large_int - 15ULL)
print("type of large_int:", type(large_int)) -- "cdata"

print("\n=== 4. Memory Management & ffi.gc Finalizers ===")
-- When allocating raw heap memory or OS resources, you can attach a garbage-collection
-- finalizer via ffi.gc, preventing leaks when the Lua reference drops.

ffi.cdef[[
    void *malloc(size_t size);
    void free(void *ptr);
]]

local function allocate_c_buffer(byte_count)
    local raw_ptr = ffi.C.malloc(byte_count)
    if raw_ptr == nil then
        error("Out of memory!")
    end

    -- Zero the memory
    ffi.fill(raw_ptr, byte_count, 0)

    -- Attach automatic destructor: free() is called when the object is GC'd
    local managed_ptr = ffi.gc(raw_ptr, function(p)
        print("  -> Finalizer invoked: freeing C buffer at", p)
        ffi.C.free(p)
    end)

    return managed_ptr
end

do
    print("Allocating 1024-byte C buffer inside a local scope...")
    local buf = allocate_c_buffer(1024)
    local byte_array = ffi.cast("uint8_t *", buf)
    byte_array[0] = 0xAA
    byte_array[1] = 0xBB
    print(string.format("First bytes: 0x%02X 0x%02X", byte_array[0], byte_array[1]))
    -- 'buf' goes out of scope here
end

-- Force garbage collection to trigger the finalizer
print("Triggering collectgarbage()...")
collectgarbage("collect")

print("\n[OK] advanced/ffi_memory_and_structs.lua completed successfully.")
