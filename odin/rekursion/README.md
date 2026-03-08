# Rekursion - Scheme Interpreter in Odin

A Scheme bytecode interpreter written in Odin.

## Features

-   **Core Scheme**: `define`, `lambda`, `if`, `quote`, `cons`, `car`, `cdr`, arithmetic primitives.
-   **Delimited Continuations**: `shift` and `reset` for advanced control flow.
-   **Vectors**: Literal syntax `[...]` (e.g., `[1 2 3]`).
-   **Tables**: Hash maps with prototypal inheritance (`table`, `get`, `set`, `set-parent`).
-   **Variadic Functions**: Support for `(define (f . args) ...)` or `(lambda (x . y) ...)`.

## Build & Run

### Prerequisites
-   Odin compiler

### Commands

**Build:**
```bash
make build
```

**Run REPL:**
```bash
make run
```

**Run Unit Tests:**
```bash
make test
```

**Run Feature Tests:**
```bash
make test-features
```

## Directory Structure

-   `src/`: Odin source code.
-   `tests/`: Scheme test files.
<div style="background-color: #fcf8e3; padding: 10px; border: 1px solid #faebcc;">
	This is a highlighted block of text.
</div>