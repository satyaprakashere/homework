#!/usr/bin/env bash
set -euo pipefail

# Ensure binaries in cargo/go/wasm-tools are on PATH
export PATH="$HOME/.cargo/bin:$HOME/go/bin:/usr/local/opt/wasm-tools/bin:$PATH"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

mkdir -p dist

echo "========================================================"
echo "🔨 Building WASM Components communicating via WIT"
echo "========================================================"

# 1. Build Rust Engine (Exports example:calculator/engine-api)
echo "🦀 [1/4] Building Rust Engine component..."
cargo build --manifest-path rust-engine/Cargo.toml --target wasm32-wasip2 --release
cp rust-engine/target/wasm32-wasip2/release/rust_engine.wasm dist/rust-engine.wasm

# 2. Build Go Runner (Imports example:calculator/engine-api)
echo "🐹 [2/4] Building Go Runner component..."
(
    cd go-runner
    wit-bindgen-go generate --world runner ../wit/calculator.wit
    go mod tidy
    tinygo build -target=wasip1 -scheduler=none -o go_runner.core.wasm .
)
wasm-tools component embed wit/calculator.wit --world runner go-runner/go_runner.core.wasm -o go-runner/go_runner.embed.wasm
wasm-tools component new go-runner/go_runner.embed.wasm --adapt wasi_snapshot_preview1=adapters/wasi_snapshot_preview1.command.wasm -o dist/go-runner.wasm

# 3. Build Go Engine (Exports example:calculator/engine-api)
echo "🐹 [3/4] Building Go Engine component..."
(
    cd go-engine
    wit-bindgen-go generate --world engine ../wit/calculator.wit
    go mod tidy
    tinygo build -target=wasip1 -scheduler=none -buildmode=c-shared -o go_engine.core.wasm .
)
wasm-tools component embed wit/calculator.wit --world engine go-engine/go_engine.core.wasm -o go-engine/go_engine.embed.wasm
wasm-tools component new go-engine/go_engine.embed.wasm --adapt wasi_snapshot_preview1=adapters/wasi_snapshot_preview1.reactor.wasm -o dist/go-engine.wasm

# 4. Build Rust Runner (Imports example:calculator/engine-api)
echo "🦀 [4/4] Building Rust Runner component..."
cargo build --manifest-path rust-runner/Cargo.toml --target wasm32-wasip2 --release
cp rust-runner/target/wasm32-wasip2/release/rust_runner.wasm dist/rust-runner.wasm

# 5. Compose components using wac (WebAssembly Composable)
echo "🧩 [5/5] Composing cross-language components with wac..."

# Scenario A: Go Runner + Rust Engine
wac plug --plug dist/rust-engine.wasm dist/go-runner.wasm -o dist/composed-go-calling-rust.wasm

# Scenario B: Rust Runner + Go Engine
wac plug --plug dist/go-engine.wasm dist/rust-runner.wasm -o dist/composed-rust-calling-go.wasm

echo "========================================================"
echo "✅ Build completed successfully! Artifacts in dist/:"
ls -lh dist/*.wasm
echo "========================================================"
