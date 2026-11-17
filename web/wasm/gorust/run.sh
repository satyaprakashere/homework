#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if [[ ! -f dist/composed-go-calling-rust.wasm || ! -f dist/composed-rust-calling-go.wasm ]]; then
    echo "⚡ Artifacts not found. Running build first..."
    ./build.sh
fi

echo "================================================================"
echo "🎯 Scenario 1: Go Runner (Consumer) calling Rust Engine (Provider)"
echo "================================================================"
wasmtime run dist/composed-go-calling-rust.wasm

echo ""
echo "================================================================"
echo "🎯 Scenario 2: Rust Runner (Consumer) calling Go Engine (Provider)"
echo "================================================================"
wasmtime run dist/composed-rust-calling-go.wasm

echo ""
echo "================================================================"
echo "🎉 Both cross-language WASM Component Model scenarios succeeded!"
echo "================================================================"
