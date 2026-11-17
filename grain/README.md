# Grain Language Examples & WebAssembly Guide 🌾

[Grain](https://grain-lang.org) is a modern, strongly-typed functional programming language that compiles directly to **WebAssembly (WASM)**.

This repository provides clean, verified examples covering core language concepts through WebAssembly compilation and runtime execution. None of the files use numbered prefixes, per repository convention.

---

## Quick Reference: Running & Compiling

### 1. Run a Grain script directly
The `grain` CLI compiles and executes the file immediately via its built-in WASI runner:
```bash
grain hello_world.gr
```

### 2. Compile Grain to WebAssembly (`grain to wasm`)
To compile `.gr` files to a standalone WebAssembly binary (`.wasm`):
```bash
grain compile wasm_interop.gr -o wasm_interop.wasm
```

Useful compiler flags:
- `--release`: Compile with optimizations for production.
- `--wat`: Produce human-readable WebAssembly Text format (`.wat`) alongside the binary.
- `-o <filename>`: Specify the output WASM file name.

### 3. Run the compiled `.wasm` file
Run using the Grain WASI runner:
```bash
grain run wasm_interop.wasm
```

Or run directly from **Node.js** using standard `node:wasi` (no extra npm packages required):
```bash
node run_wasm.mjs wasm_interop.wasm
```

Or with any external WebAssembly runtime like **Wasmtime** or **Wasmer**:
```bash
wasmtime wasm_interop.wasm
```

---

## Example Files Overview

All examples are verified and tested against Grain 0.7:

| File | Concepts Covered |
| :--- | :--- |
| [`hello_world.gr`](./hello_world.gr) | Module declarations (`module Main`), printing values, top-level execution. |
| [`variables_and_mutability.gr`](./variables_and_mutability.gr) | Immutable `let` bindings, mutable variables (`let mut`), variable shadowing, block expressions. |
| [`primitive_types.gr`](./primitive_types.gr) | Exact rational numbers (`1/3`), integers, floats, fixed-width types (`Int32`, `Float64`), `Char`, `String`, `Bool`, `Void`. |
| [`functions_and_closures.gr`](./functions_and_closures.gr) | Arrow function syntax, block bodies, closures, lexical scoping, recursion with `let rec`, higher-order functions. |
| [`tuples_and_records.gr`](./tuples_and_records.gr) | Heterogeneous tuples, tuple destructuring, typed records, mutable record fields (`mut`), functional record updates (`...record`). |
| [`enums_and_pattern_matching.gr`](./enums_and_pattern_matching.gr) | Simple enums, algebraic data types (variants with payloads), pattern matching with `match`, guards (`when`), wildcard patterns (`_`). |
| [`lists_and_arrays.gr`](./lists_and_arrays.gr) | Singly-linked lists (`[...]`), mutable arrays (`[> ...]`), standard library imports (`from "list" include List`), custom pipeline operator `(\|>`). |
| [`option_and_result.gr`](./option_and_result.gr) | Safe error handling without nulls: `Some`/`None` options, `Ok`/`Err` results, unwrapping, pattern matching outcomes. |
| [`wasm_interop.gr`](./wasm_interop.gr) | Exporting functions with `provide`, compiling to `.wasm`, inspecting module exports and WASI imports. |
| [`run_wasm.mjs`](./run_wasm.mjs) | Standalone Node.js script to load and execute compiled Grain WebAssembly binaries via WASI preview1. |

---

## Grain to WebAssembly Workflow

### Step 1: Write Grain Code with Exports
Mark functions or variables you want to export with `provide`:
```grain
module WasmInterop

provide let add = (a: Number, b: Number) => {
  a + b
}
```

### Step 2: Compile to WASM
```bash
grain compile wasm_interop.gr -o wasm_interop.wasm
```

### Step 3: Inspect the Generated WebAssembly
To inspect exports, imports, and wat disassembly:
```bash
grain compile --wat wasm_interop.gr -o wasm_interop.wasm
head -n 40 wasm_interop.wat
```

### Step 4: Run the WASM binary
```bash
node run_wasm.mjs wasm_interop.wasm
```
