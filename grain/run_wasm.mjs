// run_wasm.mjs
// Run a Grain-compiled WebAssembly (.wasm) file directly in Node.js
//
// Usage:
//   node run_wasm.mjs wasm_interop.wasm

import { readFileSync } from "node:fs";
import { WASI } from "node:wasi";

const wasmFile = process.argv[2] || "wasm_interop.wasm";

console.log(`🌾 Loading WebAssembly binary: ${wasmFile}`);

// Set up standard WASI preview1 environment
const wasi = new WASI({
  version: "preview1",
  args: [wasmFile],
  env: process.env,
});

const wasmBuffer = readFileSync(wasmFile);

// Instantiate the WebAssembly module with WASI imports
const { instance, module } = await WebAssembly.instantiate(wasmBuffer, {
  wasi_snapshot_preview1: wasi.wasiImport,
});

console.log("Exports available in WASM module:",
  WebAssembly.Module.exports(module).map(e => `${e.name} (${e.kind})`)
);

console.log("\n--- Executing WASI _start ---");
wasi.start(instance);
console.log("--- Execution Completed Successfully ---\n");
