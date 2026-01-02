const wasmBuffer = await Bun.file("fib.wasm").arrayBuffer();
const wasmModule = await WebAssembly.instantiate(wasmBuffer);
const { add } = wasmModule.instance.exports;

console.log("5 + 3 =", add(5, 3)); // Outputs: 8