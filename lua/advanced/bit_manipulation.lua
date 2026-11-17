-- ==============================================================================
-- advanced/bit_manipulation.lua: Bitwise Operations & Binary Data Handling
-- Compatible with: LuaJIT (uses LuaJIT's built-in 'bit' module)
-- Run with: luajit advanced/bit_manipulation.lua
-- ==============================================================================

-- Lua 5.1 lacked native bitwise operators (&, |, ^ were added in Lua 5.3).
-- LuaJIT includes a highly optimized C-level 'bit' module that is JIT-compiled
-- directly into single-cycle CPU instructions (AND, OR, XOR, SHL, SHR, etc.).

local bit = require("bit")

print("=== 1. Basic Bitwise Operations ===")
local a = 0x0F  -- 0000 1111 (15)
local b = 0x33  -- 0011 0011 (51)

print("bit.band(a, b):", bit.tohex(bit.band(a, b), 2)) -- 0x03
print("bit.bor(a, b): ", bit.tohex(bit.bor(a, b), 2))  -- 0x3F
print("bit.bxor(a, b):", bit.tohex(bit.bxor(a, b), 2)) -- 0x3C
print("bit.bnot(a):   ", bit.tohex(bit.bnot(a), 8))

-- Bit shifting
print("\nShifts & Rotations:")
print("bit.lshift(1, 4): ", bit.lshift(1, 4))        -- 16
print("bit.rshift(64, 2):", bit.rshift(64, 2))       -- 16
print("bit.rol(0x01, 4): ", bit.tohex(bit.rol(0x01, 4), 2)) -- 0x10
print("bit.ror(0x80, 2): ", bit.tohex(bit.ror(0x80, 2), 2)) -- 0x20

print("\n=== 2. Bitmask Flags / Permissions ===")
local FLAG_READ    = bit.lshift(1, 0) -- 0x01 (1)
local FLAG_WRITE   = bit.lshift(1, 1) -- 0x02 (2)
local FLAG_EXECUTE = bit.lshift(1, 2) -- 0x04 (4)
local FLAG_ADMIN   = bit.lshift(1, 3) -- 0x08 (8)

local function create_permissions(...)
    local flags = 0
    for i = 1, select("#", ...) do
        flags = bit.bor(flags, select(i, ...))
    end
    return flags
end

local function has_permission(flags, perm)
    return bit.band(flags, perm) == perm
end

local user_perms = create_permissions(FLAG_READ, FLAG_WRITE)
print("User has READ?   ", has_permission(user_perms, FLAG_READ))
print("User has WRITE?  ", has_permission(user_perms, FLAG_WRITE))
print("User has EXECUTE?", has_permission(user_perms, FLAG_EXECUTE))
print("User has ADMIN?  ", has_permission(user_perms, FLAG_ADMIN))

-- Grant execute
user_perms = bit.bor(user_perms, FLAG_EXECUTE)
print("After granting EXECUTE:")
print("User has EXECUTE?", has_permission(user_perms, FLAG_EXECUTE))

-- Revoke write
user_perms = bit.band(user_perms, bit.bnot(FLAG_WRITE))
print("After revoking WRITE:")
print("User has WRITE?  ", has_permission(user_perms, FLAG_WRITE))

print("\n=== 3. Packing & Unpacking 32-bit RGBA Colors ===")
-- Pack four 8-bit channels into a single 32-bit unsigned integer
local function pack_rgba(r, g, b, a)
    return bit.bor(
        bit.lshift(bit.band(r, 0xFF), 24),
        bit.lshift(bit.band(g, 0xFF), 16),
        bit.lshift(bit.band(b, 0xFF), 8),
        bit.band(a, 0xFF)
    )
end

-- Unpack a 32-bit integer back into individual channels
local function unpack_rgba(color)
    local r = bit.band(bit.rshift(color, 24), 0xFF)
    local g = bit.band(bit.rshift(color, 16), 0xFF)
    local b = bit.band(bit.rshift(color, 8), 0xFF)
    local a = bit.band(color, 0xFF)
    return r, g, b, a
end

local color = pack_rgba(255, 128, 64, 200)
print(string.format("Packed color: #%s", bit.tohex(color, 8)))

local r, g, b, a_val = unpack_rgba(color)
print(string.format("Unpacked: R=%d, G=%d, B=%d, A=%d", r, g, b, a_val))

print("\n=== 4. Implementing CRC-32 with the 'bit' Module ===")
-- Generate CRC32 lookup table
local crc_table = {}
for i = 0, 255 do
    local c = i
    for _ = 1, 8 do
        if bit.band(c, 1) ~= 0 then
            c = bit.bxor(0xEDB88320, bit.rshift(c, 1))
        else
            c = bit.rshift(c, 1)
        end
    end
    crc_table[i] = c
end

local function crc32(str)
    local crc = 0xFFFFFFFF
    for i = 1, #str do
        local byte = string.byte(str, i)
        local table_idx = bit.band(bit.bxor(crc, byte), 0xFF)
        crc = bit.bxor(crc_table[table_idx], bit.rshift(crc, 8))
    end
    return bit.bxor(crc, 0xFFFFFFFF)
end

local sample_text = "The quick brown fox jumps over the lazy dog"
local checksum = crc32(sample_text)
print("Sample text:", sample_text)
print(string.format("CRC-32: 0x%s", string.upper(bit.tohex(checksum, 8))))

print("\n[OK] advanced/bit_manipulation.lua completed successfully.")
