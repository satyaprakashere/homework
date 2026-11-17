# Goose Programming Language Examples & Learning Guide

Welcome to the **Goose Programming Language** learning repository.

Goose is a memory-safe systems programming language designed by **Wouter van Oortmerssen** (`aardappel`, also creator of the Lobster programming language). Goose achieves exceptional runtime performance and memory safety **without a garbage collector, without a traditional heap allocator, and without manual lifetime annotations** (such as Rust's `'a`).

All example files in this repository use clean, descriptive names **without numbered prefixes** (e.g., `tour.goose`, `memory.goose`, `strings.goose`, etc.).

---

## 🚀 Key Architectural Concepts of Goose

### 1. Compiler-Managed Data Stacks (No Heap, No GC)
In traditional languages:
- **C/C++**: Relies on `malloc`/`free` or `new`/`delete` (risk of leaks, use-after-free, double-free).
- **Rust**: Relies on affine types, ownership, and explicit lifetime annotations (`'a`) for memory safety.
- **Go/Java/C#**: Relies on a tracing garbage collector that incurs pause times and memory overhead.

**Goose's Model**:
- All dynamic values live inline on compiler-managed data stacks (using reserved multi-gigabyte virtual address ranges with bump pointers).
- Memory allocation is a simple pointer bump (sub-nanosecond).
- Memory deallocation happens automatically when the enclosing scope exits ("scope exit is the free").
- The compiler automatically infers reference lifetimes and prevents any reference from outliving its owner.

### 2. References that Survive Growth
In languages like C++ (`std::vector`) or Rust (`Vec`), pushing elements to a growing vector can reallocate the backing buffer, invalidating existing pointers. In Goose:
- Grow-only arrays (`T[>..]`) allocate new blocks on the data stack without moving previously allocated elements.
- References to existing items remain valid even while appending new items.

### 3. The Array Family & Slices
Goose provides specialized inline array types rather than a single heap-allocated container:
- `T[N]`: Fixed-size array of $N$ items allocated inline.
- `T[:]`: Slice (pointer + length) representing a zero-copy view into any array or sub-range.
- `T[>..]`: Grow-only array (elements never move upon growth).
- `T[>..<]`: Grow-shrink array for stacks, queues, and heaps.
- `u8[..16]`: Small string inline buffer inside structs.
- `u8[>..]`: Fast string builder.

### 4. Algebraic Data Types (Enums) in Two Sizes
- **Fixed Mode (`enum Shape`)**: Like Rust enums or C++ variants; sized to the largest variant. Directly indexable in arrays.
- **Variable Mode (`Shape..`)**: Tightly packed so each instance occupies only the bytes required by its active variant. Iterated sequentially or accessed via index links.

### 5. Control Flow as Expressions
- `if`/`else` and `match` evaluate to values, enabling concise, functional expressions.
- Functions support multiple return values as a calling convention (e.g., `-> i64, bool`).

---

## 📂 Example Catalog

The examples below are organized by category and difficulty.

### 1. Foundations & Language Basics

| File | Concepts Covered |
| :--- | :--- |
| [hello_world.goose](hello_world.goose) | Minimal starting point: `fn main()`, printing, string slice parameters, basic math, fixed arrays. |
| [tour.goose](tour.goose) | Broad tour: scalar types, array kinds, slices, structs, control flow expressions, multiple returns, optionals (`?`), references (`.=` and `.==`). |
| [memory.goose](memory.goose) | Deep dive into Goose's memory model: references surviving array growth, scope-based cleanup, scratch buffers, grow-shrink stacks. |
| [strings.goose](strings.goose) | `u8` arrays as strings, builders (`u8[>..]`), string slices (`u8[:]`), search/split/trim, UTF-8 code point decoding, custom format overloads. |
| [errors.goose](errors.goose) | Error idioms: trailing bool status, optionals narrowed by `if`/`guard`, `return ... from` for deep failure bailouts, assertions. |
| [shapes.goose](shapes.goose) | Algebraic data types (ADTs) in fixed and variable mode, pattern matching by value and reference, virtual-dispatch idioms. |
| [functions.goose](functions.goose) | Generics without declaration (monomorphization), function overloading, UFCS (Unified Function Call Syntax), higher-order functions. |

### 2. Classic Algorithms

| File | Concepts Covered |
| :--- | :--- |
| [sieve.goose](sieve.goose) | Sieve of Eratosthenes: loops with compiler-proven bounds check elimination, Euclidean `%`, wrapping integer hashes. |
| [bignum.goose](bignum.goose) | Arbitrary-precision math on `u32` limbs with `u64` carries ($100!$, $\text{fib}(500)$, $2^{1000}$), decimal formatting. |
| [sorting.goose](sorting.goose) | Insertion sort, caller-allocated merge sort, binary search, and stdlib `sort`/`stable_sort` over slices. |
| [sudoku.goose](sudoku.goose) | Backtracking solver with `u16` bitmask candidates and heuristic cell ordering; single struct passed by reference. |
| [maze.goose](maze.goose) | BFS and Dijkstra pathfinding over a 2D byte grid, grow-only queues, and heap operations (`heap_push`/`heap_pop`). |
| [huffman.goose](huffman.goose) | Frequency counting, priority queue, prefix tree with relative links, bit-level packing and decoding. |

### 3. Data Structures & File Parsing

| File | Concepts Covered |
| :--- | :--- |
| [linked_list.goose](linked_list.goose) | Doubly linked list in a reusable slot pool using `in pool` relative links and sentinel nodes; $O(1)$ operations. |
| [bst.goose](bst.goose) | Binary search tree inside a flat grow-only pool with self-relative links; recursive traversals with caller-owned output. |
| [word_freq.goose](word_freq.goose) | Zero-copy word frequency counter using `dictionary<u8[:], i32>` with slices pointing directly into text loaded from `data/alice.txt`. |
| [records.goose](records.goose) | Flat array of variable-size order records with inline variable-length strings and item lists. |
| [calc.goose](calc.goose) | Interactive recursive descent calculator: lexing tokens, operator precedence, local variable dictionary, and error recovery. |
| [json.goose](json.goose) | Full JSON parser and renderer: variable-mode AST nodes in a flat pool with 4-byte links, pretty/compact serializers. |
| [vm.goose](vm.goose) | Stack bytecode virtual machine: instruction enum, bytecode execution loop, disassembler, and test programs. |

### 4. Systems, Graphics, Simulation & Concurrency

| File | Concepts Covered |
| :--- | :--- |
| [life.goose](life.goose) | Conway's Game of Life on a toroidal grid: dual-buffer swapping, Euclidean wraparound, ASCII visualization. |
| [raytrace.goose](raytrace.goose) | 3D Raytracer: sphere intersections, diffuse/specular shading, shadows, and reflections using `float3` math. |
| [image_filters.goose](image_filters.goose) | Box blur and Sobel edge detection over grayscale pixel slices; generates `.pgm` images. |
| [mandelbrot_threads.goose](mandelbrot_threads.goose) | Multithreaded Mandelbrot renderer using worker queues and flat row buffers. |
| [call_c.goose](call_c.goose) | C Interoperability: calling C functions defined in `call_c.h` and `libm` via `extern fn`. |
| [serialize.goose](serialize.goose) | Binary serialization: safe zero-copy dumping and loading (`bytes_of`, `to_bytes`, `from_bytes`) with validation. |
| [file_tree.goose](file_tree.goose) | In-memory filesystem tree using stdlib `slot_pool` and `slice_pool` for dynamic node and link reuse. |
| [pool_worker_snapshots.goose](pool_worker_snapshots.goose) | Multithreaded pool snapshots and worker synchronization. |
| [gfx_cube.goose](gfx_cube.goose) | 3D hardware-accelerated spinning cube with GLSL shaders using Goose's `gfx` package. |
| [physics_boxes.goose](physics_boxes.goose) | 3D rigid-body physics simulation using Box3D and instanced rendering. |
| [ui_todo.goose](ui_todo.goose) | Immediate-mode UI todo application using Nuklear widgets. |
| [mini_minecraft.goose](mini_minecraft.goose) | Complete voxel sandbox game with procedural terrain, day/night cycles, lighting, and crafting. |
| [mini_doom.goose](mini_doom.goose) | Raycasting FPS game engine rendering classic WAD levels. |

---

## 🛠️ How to Run & Build Examples

### Method 1: Using the Included Go Runner Script
Per workspace guidelines, a Go runner script ([runner.go](runner.go)) is provided:

```bash
# Run a specific example
go run runner.go hello_world
go run runner.go tour
go run runner.go sorting
go run runner.go word_freq

# Run all non-interactive console examples with test summary
go run runner.go -all

# Display available examples and help
go run runner.go
```

### Method 2: Using the Goose CLI Directly

Run any example immediately inside the compiler's in-process engine:
```bash
goose hello_world.goose
goose tour.goose
goose memory.goose
```

Pass arguments to Goose programs using `--`:
```bash
goose word_freq.goose -- data/alice.txt
```

Compile directly into a native executable using your local C compiler:
```bash
goose build tour.goose
./tour
```

Emit readable C source code:
```bash
goose -o tour.c tour.goose
```

### Method 3: Running C Interop Examples
When running examples that import C headers:
```bash
goose --include call_c.h call_c.goose
```

---

## 📖 Recommended Learning Path

1. **Start with [hello_world.goose](hello_world.goose)** to verify your setup and understand basic syntax.
2. **Read and run [tour.goose](tour.goose)** for a complete guided overview of core constructs.
3. **Study [memory.goose](memory.goose)** to understand Goose's revolutionary memory model (stack allocation, bump pointers, surviving references).
4. **Explore [strings.goose](strings.goose)** and **[shapes.goose](shapes.goose)** for practical string manipulation and algebraic data types.
5. **Inspect [errors.goose](errors.goose)** and **[functions.goose](functions.goose)** to write idiomatic functions.
6. **Dive into real-world applications** such as [word_freq.goose](word_freq.goose), [calc.goose](calc.goose), [json.goose](json.goose), and [raytrace.goose](raytrace.goose).
