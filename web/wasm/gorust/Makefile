.PHONY: all build run clean help

all: build run

build:
	@chmod +x build.sh run.sh
	@./build.sh

run:
	@./run.sh

clean:
	@rm -rf dist/
	@rm -rf rust-engine/target/
	@rm -rf rust-runner/target/
	@rm -f go-runner/*.wasm
	@rm -f go-engine/*.wasm
	@echo "🧹 Cleaned all build artifacts."

help:
	@echo "Available commands:"
	@echo "  make build   - Builds all Rust & Go components and composes them"
	@echo "  make run     - Runs both cross-language WASM components in wasmtime"
	@echo "  make clean   - Cleans compiled binaries and temporary artifacts"
	@echo "  make all     - Builds and runs the demo"
