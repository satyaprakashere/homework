# Homework Repository Automation Scripts

High-performance, zero-dependency Go automation scripts for building and cleaning polyglot projects across 35+ languages and ecosystems in the `homework` repository.

---

## Table of Contents

- [Overview](#overview)
- [Design Principles](#design-principles)
- [Quick Start](#quick-start)
- [Build Runner (`build.go`)](#build-runner-buildgo)
  - [Features](#features)
  - [Command-Line Flags](#command-line-flags)
  - [Examples](#examples)
  - [Supported Ecosystems](#supported-ecosystems)
- [Artifact Cleaner (`clean.go`)](#artifact-cleaner-cleango)
  - [Features & Safety Guarantees](#features--safety-guarantees)
  - [Command-Line Flags](#command-line-flags-1)
  - [Examples](#examples-1)
  - [Target Artifact Patterns](#target-artifact-patterns)
- [CI/CD Integration](#cicd-integration)
- [Extending the Scripts](#extending-the-scripts)

---

## Overview

The `homework` repository is a multi-language proving ground containing projects implemented in Rust, Go, C#, F#, Zig, Lean 4, Gleam, OCaml, Haskell, Java, Kotlin, Typst, Odin, Swift, and more.

Two companion Go scripts manage building and cleaning across the entire tree:
- **`build.go`** (`scripts/build.go`): Discovers and validates builds across all language ecosystems concurrently, with per-project timeouts, fast checking modes, live progress tracking, and structured diagnostics.
- **`clean.go`** (`scripts/clean.go`): Safely finds and purges build artifacts, caches, and compiler intermediates, displaying exact space reclaimed while strictly protecting git-tracked files and runtime environments.

Root symlinks (`build.go` and `clean.go`) allow execution directly from the repository root:
```bash
go run build.go
go run clean.go
```

---

## Design Principles

1. **Pure Go Standard Library**: No external dependencies (`go.mod` not required). Runs immediately with standard `go run`.
2. **Git-Aware Safety**: Queries `git ls-files` to ensure no tracked file or asset is ever deleted by clean operations.
3. **Environment Protection**: Strictly ignores and shields sensitive directories (`.git`, `.jj`, `.venv`, `.pixi`).
4. **Toolchain Detection**: Checks tool availability (`cargo`, `dotnet`, `lake`, `zig`, `dune`, etc.) in `PATH`. Missing toolchains result in informative `[SKIPPED]` statuses instead of hard crashes.
5. **Configurable Concurrency**: Builds projects in parallel using worker pools (`-j` flag) for rapid test cycles.
6. **Detailed Diagnostics**: Aggregates and prints compiler errors and execution logs in a clear summary table upon completion.

---

## Quick Start

```bash
# 1. Preview all discovered projects
go run build.go -list

# 2. Run fast build verification on all projects
go run build.go

# 3. Build only a specific ecosystem (e.g. Go, Rust, or .NET)
go run build.go -lang go
go run build.go -lang rust
go run build.go -lang dotnet

# 4. Preview build artifacts to be cleaned (dry run)
go run clean.go -dry-run

# 5. Clean build artifacts and free disk space
go run clean.go
```

---

## Build Runner (`build.go`)

### Features
- **Dynamic Project Discovery**: Scans repository trees for manifest files (`Cargo.toml`, `go.mod`, `*.csproj`, `*.fsproj`, `build.zig`, `lakefile.toml`, `gleam.toml`, `dune-project`, `pom.xml`, etc.).
- **Fast vs. Full Build**: Supports fast verification checks (e.g. `cargo check`, `go vet`, `cabal build --dry-run`) or full compiler artifact generation (`-build` flag).
- **Concurrency**: Parallel execution across CPU cores (defaults to 4 workers).
- **Timeout Protection**: Per-project deadlines (defaults to 4 minutes) prevent stalled network downloads or endless compilation steps.
- **JSON Output**: Produces structured JSON output for automated pipelines with `-json`.

### Command-Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `-lang <name>` | `""` (all) | Filter projects by language (`rust`, `go`, `dotnet`, `csharp`, `fsharp`, `zig`, `lean`, `gleam`, `ocaml`, `java`, `typst`, etc.) |
| `-project <query>` | `""` | Filter projects matching name or subpath substring |
| `-build` | `false` | Run full build rather than fast verification check |
| `-j <n>` | `4` | Number of concurrent worker threads |
| `-timeout <dur>` | `4m0s` | Per-project build timeout (e.g. `1m`, `30s`, `5m`) |
| `-v` / `-verbose` | `false` | Verbose mode: display compiler outputs even on successful builds |
| `-list` | `false` | List all discovered projects and exit without executing builds |
| `-json` | `false` | Output results in JSON format |
| `-no-color` | `false` | Disable ANSI terminal colors (also respects `NO_COLOR` env var) |

### Examples

```bash
# Verify all Go projects
go run build.go -lang go

# Verify all .NET projects (both C# and F#)
go run build.go -lang dotnet

# Run Lean 4 proofs & tutorials
go run build.go -lang lean

# Run full compilation on a specific project by name
go run build.go -project database -build

# Run 8 concurrent build workers with verbose logs
go run build.go -j 8 -v
```

### Supported Ecosystems

| Language | Manifest / Target | Fast Check Command | Full Build Command |
|----------|-------------------|--------------------|--------------------|
| **Rust** | `Cargo.toml` | `cargo check` | `cargo build` |
| **Go** | `go.mod` | `go vet ./...` | `go build ./...` |
| **C#** | `*.csproj` | `dotnet build -c Debug --nologo` | `dotnet build -c Release --nologo` |
| **F#** | `*.fsproj` | `dotnet build -c Debug --nologo` | `dotnet build -c Release --nologo` |
| **Zig** | `build.zig` | `zig build` | `zig build -Doptimize=ReleaseFast` |
| **Lean 4** | `lakefile.toml` / `lakefile.lean` | `lake build` | `lake build` |
| **Gleam** | `gleam.toml` | `gleam check` | `gleam build` |
| **OCaml** | `dune-project` | `dune build` | `dune build @all` |
| **Java** | `pom.xml` | `mvn test-compile -q` | `mvn package -DskipTests -q` |
| **Kotlin** | `build.gradle.kts` | `gradle classes -q` | `gradle build -x test -q` |
| **Haskell** | `*.cabal` | `cabal build --dry-run` | `cabal build` |
| **Typst** | `HariPath.typ` | `typst compile HariPath.typ -f pdf /dev/null` | `typst compile HariPath.typ HariPath.pdf` |
| **Odin** | `odin/fib.odin` | `odin check fib.odin -file` | `odin build fib.odin -file -out:/dev/null` |

---

## Artifact Cleaner (`clean.go`)

### Features & Safety Guarantees
- **Reclaimed Space Calculation**: Calculates exact size of removed files and folders, displaying formatted results (e.g. `52.46 MB`).
- **Dry-Run Mode**: Inspect everything that would be removed without touching disk using `-dry-run` or `-n`.
- **Git Protection**: Cross-checks paths with `git ls-files` to guarantee no tracked file is ever deleted.
- **Language & Path Filters**: Target cleanup to specific directories or language ecosystems.
- **Deep Clean Option**: Preserves package caches by default; cleans heavy dependency trees (`node_modules/`, `.spago/`) only when `-deep` is specified.

### Command-Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `-dry-run`, `-n` | `false` | Preview targets and calculate space without deleting |
| `-deep` | `false` | Deep clean: also remove dependency folders (`node_modules/`, `.spago/`) |
| `-lang <name>` | `""` | Clean only artifacts for a given language (`rust`, `go`, `dotnet`, `zig`, `lean`, etc.) |
| `-path <pattern>` | `""` | Clean only inside paths matching this substring |
| `-v` / `-verbose` | `false` | Print detailed output for each item removed |
| `-no-color` | `false` | Disable ANSI terminal colors |

### Examples

```bash
# Preview what would be cleaned across the entire repo
go run clean.go -dry-run

# Clean all build artifacts
go run clean.go

# Clean only Rust target directories
go run clean.go -lang rust

# Clean only .NET bin and obj directories
go run clean.go -lang dotnet

# Clean only within a specific project folder
go run clean.go -path csharp

# Deep clean including node_modules and package caches
go run clean.go -deep
```

### Target Artifact Patterns

- **Rust**: `target/`
- **Go**: compiled test binaries (`*.test`), standalone compiled binaries, coverage/profiling files (`*.prof`, `*.out`)
- **.NET (C# / F#)**: `bin/`, `obj/`
- **Zig**: `zig-out/`, `.zig-cache/`, `zig-pkg/`
- **Lean 4**: `.lake/`
- **OCaml / Dune**: `_build/`
- **Gleam**: `build/`
- **Java / Maven**: `target/`
- **Kotlin / Gradle**: `.gradle/`, `build/`
- **Haskell**: `dist-newstyle/`, `.stack-work/`, `*.hi`, `*.o`
- **Python**: `__pycache__/`, `*.pyc`, `*.pyo` (isolated from virtual environments)
- **Web**: `dist/`, `.turbo/`, `.next/`, `build/`
- **General**: `.DS_Store`, untracked `*.o`, `*.class`

---

## CI/CD Integration

In CI/CD environments (GitHub Actions, GitLab CI, etc.), you can run `build.go` and check the process exit code:

```bash
# Exits with 0 if all runnable projects succeed, or 1 if any build fails
go run build.go

# Or emit machine-readable JSON:
go run build.go -json > build-results.json
```

---

## Extending the Scripts

To add a new language ecosystem:
1. Open `scripts/build.go` and add the manifest check or standalone target in `discoverProjects()`.
2. Define the corresponding `Tool`, `CheckArgs`, and `BuildArgs`.
3. Open `scripts/clean.go` and register the generated output directory/file patterns in `scanTargets()`.
