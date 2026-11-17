#!/bin/sh
set -e

LUAJIT_BIN=""
if command -v luajit >/dev/null 2>&1; then
    LUAJIT_BIN="luajit"
elif [ -x "/opt/homebrew/bin/luajit" ]; then
    LUAJIT_BIN="/opt/homebrew/bin/luajit"
elif [ -x "/usr/local/bin/luajit" ]; then
    LUAJIT_BIN="/usr/local/bin/luajit"
else
    echo "Error: luajit binary not found in PATH or standard locations." >&2
    exit 1
fi

echo "=================================================="
echo "Running Lua & LuaJIT Examples with: $($LUAJIT_BIN -v)"
echo "=================================================="

FILES=(
    "basics.lua"
    "functions.lua"
    "tables.lua"
    "strings_patterns.lua"
    "metatables_oop.lua"
    "coroutines.lua"
    "error_handling.lua"
    "fibonacci.lua"
    "advanced/ffi_c_interop.lua"
    "advanced/ffi_memory_and_structs.lua"
    "advanced/metaprogramming_weak_tables.lua"
    "advanced/jit_optimization_and_traces.lua"
    "advanced/bit_manipulation.lua"
    "advanced/async_coroutine_scheduler.lua"
)

for file in "${FILES[@]}"; do
    echo ""
    echo "--------------------------------------------------"
    echo "--> Running: $file"
    echo "--------------------------------------------------"
    "$LUAJIT_BIN" "$file"
done

echo ""
echo "=================================================="
echo "All examples completed successfully!"
echo "=================================================="
