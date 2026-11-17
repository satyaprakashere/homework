import "./wasm_exec.js";

const go = new globalThis.Go();
const wasmBuffer = await Bun.file("fib.wasm").arrayBuffer();
const wasmModule = await WebAssembly.instantiate(wasmBuffer, go.importObject);

go.run(wasmModule.instance);

// The Go code sets 'addFromGo' and 'fibFromGo' on the global object
console.log("5 + 3 =", (globalThis as any).addFromGo(5, 3));
console.log("fib(10) =", (globalThis as any).fibFromGo(10));