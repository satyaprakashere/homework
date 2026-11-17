# Lua & LuaJIT Learning Guide and Code Examples

A complete, hands-on, progressive curriculum for learning **Lua** and **LuaJIT**, from language fundamentals to high-performance C interop, memory management, and asynchronous runtimes.

All examples are tested and fully compatible with **LuaJIT 2.1+** (and standard Lua 5.1/5.2 where applicable).

---

## Quick Start

### 1. Prerequisites
Ensure `luajit` is installed on your system. If `luajit` is in `/opt/homebrew/bin/luajit` or your standard `PATH`:
```bash
luajit -v
```

### 2. Run Any Single Example
```bash
# Language basics
luajit basics.lua
luajit metatables_oop.lua

# Fibonacci: Linear O(n) vs Logarithmic O(log n)
luajit fibonacci.lua

# Advanced LuaJIT systems programming
luajit advanced/ffi_c_interop.lua
luajit advanced/async_coroutine_scheduler.lua
```

### 3. Run the Entire Suite
```bash
./run_all.sh
```

---

## Curriculum Structure

### Part I: Core Lua Fundamentals

| File | Concepts Covered |
| :--- | :--- |
| [basics.lua](file:///Users/prakash/Documents/projects/homework/lua/basics.lua) | 8 primitive types, scoping (`local` vs `global`), truthiness (`0` and `""` are truthy!), `while`, `repeat-until`, numeric and generic `for`, ternary idioms, LuaJIT `goto` & labels. |
| [functions.lua](file:///Users/prakash/Documents/projects/homework/lua/functions.lua) | First-class functions, multiple return values, variadic functions (`...`) with `select()`, closures and private state, tail-call optimization, `map`/`filter`/`reduce`. |
| [tables.lua](file:///Users/prakash/Documents/projects/homework/lua/tables.lua) | Tables as 1-indexed sequences, dictionary / hash maps, length operator `#` and array holes, `table.insert`, `table.remove`, `table.sort`, `pairs` vs `ipairs`, sets, deep copying. |
| [strings_patterns.lua](file:///Users/prakash/Documents/projects/homework/lua/strings_patterns.lua) | String manipulation, buffer concatenation via `table.concat`, Lua pattern matching classes (`%a`, `%d`, `%s`, etc.), greedy vs non-greedy (`.-`), `string.find`, `string.match`, `string.gmatch`, function substitution in `string.gsub`. |
| [metatables_oop.lua](file:///Users/prakash/Documents/projects/homework/lua/metatables_oop.lua) | Metatables & metamethods (`__add`, `__tostring`, `__eq`, `__index`, `__call`), class-based OOP with single inheritance, method overriding, polymorphism, colon `:` vs dot `.` syntax. |
| [coroutines.lua](file:///Users/prakash/Documents/projects/homework/lua/coroutines.lua) | Cooperative multitasking, lifecycle states (`suspended`, `running`, `dead`), `coroutine.create`, `resume`, `yield`, bidirectional data passing, generators with `coroutine.wrap`, producer-filter-consumer pipelines. |
| [error_handling.lua](file:///Users/prakash/Documents/projects/homework/lua/error_handling.lua) | `assert`, `error(msg, level)`, protected calls with `pcall` (try/catch), `xpcall` with `debug.traceback`, custom error objects, safe `try-finally` resource cleanup pattern. |
| [fibonacci.lua](file:///Users/prakash/Documents/projects/homework/lua/fibonacci.lua) | Linear $O(n)$ iterative and tail-recursive algorithms, logarithmic $O(\log n)$ fast doubling and $2 \times 2$ matrix exponentiation, 64-bit integer handling (`uint64_t` / `ULL` literals up to $F(93)$), modular arithmetic for astronomical indices like $F(10^9) \pmod{10^9+7}$, and benchmark comparisons. |

---

### Part II: Advanced LuaJIT & Metaprogramming (`advanced/`)

| File | Concepts Covered |
| :--- | :--- |
| [advanced/ffi_c_interop.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/ffi_c_interop.lua) | LuaJIT Foreign Function Interface (FFI). Declaring C symbols with `ffi.cdef`, direct zero-overhead libc calls (`getpid`, `sin`, `sqrt`, `puts`), passing Lua functions as C callbacks (`qsort`), converting between C char pointers and Lua strings. |
| [advanced/ffi_memory_and_structs.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/ffi_memory_and_structs.lua) | Defining C structs, `ffi.metatype` (attaching OOP methods directly to C structs), `sizeof`/`alignof`/`offsetof`, native 64-bit integers (`uint64_t` / `ULL` literals), manual buffer allocation with automatic garbage-collected destructors via `ffi.gc`. |
| [advanced/metaprogramming_weak_tables.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/metaprogramming_weak_tables.lua) | Proxy tables for 100% transparent access logging, read-only immutable tables, autovivification (auto-instantiating deep nested tables), weak tables (`__mode = "k"`), memory-leak-free memoization caches. |
| [advanced/jit_optimization_and_traces.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/jit_optimization_and_traces.lua) | LuaJIT architecture: handwritten assembly interpreter vs trace compiler. JIT control with `jit.status()`, live trace inspection via `jit.v`, NYI (Not Yet Implemented) trace abort causes, rules of thumb for high-performance Lua. |
| [advanced/bit_manipulation.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/bit_manipulation.lua) | LuaJIT `bit` library (`band`, `bor`, `bxor`, `bnot`, `lshift`, `rshift`, `rol`, `ror`, `tohex`). Bitmask permissions, 32-bit RGBA color packing/unpacking, full implementation of CRC-32 checksum. |
| [advanced/async_coroutine_scheduler.lua](file:///Users/prakash/Documents/projects/homework/lua/advanced/async_coroutine_scheduler.lua) | Cooperative async runtime / event loop written from scratch. Non-blocking task spawning, timed sleeping, inter-task async channels (`send`/`recv`), concurrent producer-consumer workers. |

---

## Key Lua & LuaJIT Quirks to Remember

1. **1-Based Indexing**: Sequences and array indices start at `1`, not `0` (e.g., `arr[1]` is the first element). However, C arrays created via `ffi.new("int[?]", n)` are 0-indexed!
2. **Truthiness**: Only `false` and `nil` evaluate to false. `0`, empty strings `""`, and empty tables `{}` are all **truthy**!
3. **Tables are the Only Data Structure**: Lua uses tables for arrays, hash maps, sets, objects, and namespaces.
4. **Local by Default**: Always use `local x = ...`. Omitting `local` assigns into the global environment `_G`.
5. **No Built-in Classes**: OOP is implemented using metatables and prototypes with the `:` syntax: `obj:method(arg)` expands to `obj.method(obj, arg)`.
6. **FFI Speed**: LuaJIT FFI avoids the Lua C-API stack overhead and enables the JIT compiler to inline C struct access directly into CPU registers and memory offsets.
