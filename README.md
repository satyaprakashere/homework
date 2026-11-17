# Homework: The Polyglot Programming Laboratory

A multi-paradigm, multi-language research laboratory exploring language ergonomics, type theory, runtime models, formal verification, and systems engineering across 35+ programming languages.

## Project Scope & Disciplines

Homework serves as the active proving ground for:
- **Formal Verification & Theorem Proving**: Lean 4, Agda, Idris 2, Arend, F*.
- **Systems & Low-Level Runtimes**: Odin, Zig, Rust, C, C++, Ada, Fortran, Objective-C.
- **Pure Functional & Type-Driven Languages**: Haskell, OCaml, Clean/Unison, Grain, Gleam, Roc, F#.
- **Dynamic & Scripting Environments**: Julia, Lua, Mojo, Python, Ruby, Crystal, Elixir, Erlang.
- **Lisp, JVM & Hosted Runtimes**: Clojure, Racket, Scheme, Common Lisp, Java, Kotlin, Scala, C# (.NET 9).
- **Document Systems & Typesetting**: Typst (HariPath & devotional treatises), LaTeX.
- **Custom Dialects**: Aloha, Rekursion, Prakrit, Padini.

## Structure

Each sub-directory contains dedicated source trees, build recipes, and test suites:
- `odin/`: High-performance systems programming, memory allocators, Raylib graphics, and tail-call benchmarks.
- `lean/`: Type-theoretic proofs and algebraic formalizations.
- `haskell/`: QuickCheck property-based testing and algebraic structures.
- `typst/`: Typeset documents including HariPath with dynamic theme palettes.
- `csharp/`: Modern .NET showcase applications and data pipelines.
- `ruby/`: Expressive meta-programming and DSL implementations.
- `go/`: Concurrent systems design patterns and distributed primitives.

## Running Tests & Builds

### Automated Build & Clean (Go Scripts)

Unified Go scripts manage building and cleaning across all language projects:

```bash
# Build & verify all projects across all ecosystems
go run build.go

# Fast verification check
go run build.go -fast

# Target a specific language ecosystem (e.g. go, rust, dotnet, lean, gleam)
go run build.go -lang go
go run build.go -lang dotnet

# Preview all discovered projects
go run build.go -list

# Clean all build artifacts, compiler intermediates, and caches
go run clean.go

# Preview clean operations (dry-run)
go run clean.go -dry-run

# Clean a specific language or subpath
go run clean.go -lang rust
go run clean.go -path csharp
```
For complete flags and options, see [scripts/README.md](file:///Users/prakash/Documents/projects/homework/scripts/README.md).

### Direct Language Toolchains

Refer to individual toolchains as needed:
- **Odin**: `odin run odin/<file>.odin -file`
- **Haskell**: `runhaskell haskell/qsort.hs`
- **Lean**: `lake build` in `lean/`
- **Typst**: `typst compile typst/HariPath.typ typst/HariPath.pdf`
