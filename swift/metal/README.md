# Advanced Metal & MSL (Metal Shading Language) in Swift

A comprehensive, production-grade guide and curriculum for mastering advanced GPU computing (GPGPU), modern graphics architectures, and low-overhead compute pipelines using **Apple Metal** and **Swift**.

---

## 📚 Curriculum & Examples

All examples are standalone Swift files paired with dedicated companion Metal Shading Language (`.metal`) shader files, performance benchmarks, and correctness verification against CPU ground truth.

| Swift File | Metal Shader | Topic | Key Concepts |
| :--- | :--- | :--- | :--- |
| **[`01_MatrixMultiplication_Tiled_SIMD.swift`](file:///Users/prakash/Documents/homework/swift/metal/01_MatrixMultiplication_Tiled_SIMD.swift)** | **[`01_MatrixMultiplication_Tiled_SIMD.metal`](file:///Users/prakash/Documents/homework/swift/metal/01_MatrixMultiplication_Tiled_SIMD.metal)** | High-Performance GEMM | Threadgroup tiling, 2D register blocking, shared SRAM cache, memory coalescing, GFLOPS profiling. |
| **[`02_ParallelReduction_PrefixSum.swift`](file:///Users/prakash/Documents/homework/swift/metal/02_ParallelReduction_PrefixSum.swift)** | **[`02_ParallelReduction_PrefixSum.metal`](file:///Users/prakash/Documents/homework/swift/metal/02_ParallelReduction_PrefixSum.metal)** | Reductions & Scans | Multi-pass reduction, `simd_shuffle_down`, Blelloch parallel exclusive prefix sum (scan), shared memory barriers. |
| **[`03_NBody_Particle_Simulation.swift`](file:///Users/prakash/Documents/homework/swift/metal/03_NBody_Particle_Simulation.swift)** | **[`03_NBody_Particle_Simulation.metal`](file:///Users/prakash/Documents/homework/swift/metal/03_NBody_Particle_Simulation.metal)** | GPGPU Particle Physics | $O(N^2)$ tiled gravitational simulation, zero-copy compute-to-render buffer sharing, ping-pong double buffering. |
| **[`04_Raymarching_SDF.swift`](file:///Users/prakash/Documents/homework/swift/metal/04_Raymarching_SDF.swift)** | **[`04_Raymarching_SDF.metal`](file:///Users/prakash/Documents/homework/swift/metal/04_Raymarching_SDF.metal)** | Volumetric SDF Raymarching | Sphere tracing, smooth CSG min (`smin`), numerical normal gradients, soft shadow penumbra, ambient occlusion. |
| **[`05_Compute_Image_Processing.swift`](file:///Users/prakash/Documents/homework/swift/metal/05_Compute_Image_Processing.swift)** | **[`05_Compute_Image_Processing.metal`](file:///Users/prakash/Documents/homework/swift/metal/05_Compute_Image_Processing.metal)** | GPGPU Convolutions | `MTLTexture` read/write access, 2-pass separable Gaussian blur ($O(2K)$ vs $O(K^2)$), Sobel edge gradient filter. |
| **[`06_ArgumentBuffers_IndirectDraw.swift`](file:///Users/prakash/Documents/homework/swift/metal/06_ArgumentBuffers_IndirectDraw.swift)** | **[`06_ArgumentBuffers_IndirectDraw.metal`](file:///Users/prakash/Documents/homework/swift/metal/06_ArgumentBuffers_IndirectDraw.metal)** | Argument Buffers & ICBs | Modern bindless resource tables (`MTLArgumentEncoder`), GPU-driven Indirect Command Buffers (ICB), GPU culling. |
| **[`07_TripleBuffering_Synchronization.swift`](file:///Users/prakash/Documents/homework/swift/metal/07_TripleBuffering_Synchronization.swift)** | **[`07_TripleBuffering_Synchronization.metal`](file:///Users/prakash/Documents/homework/swift/metal/07_TripleBuffering_Synchronization.metal)** | CPU-GPU Synchronization | Triple-buffering ring memory model, 256-byte alignment, zero CPU-GPU race conditions, eliminating pipeline stalls. |

---

## 🚀 How to Run the Examples

You can run any example directly using the Swift interpreter or compile with optimization:

### Running directly with Swift CLI:
```bash
cd metal
swift 01_MatrixMultiplication_Tiled_SIMD.swift
swift 02_ParallelReduction_PrefixSum.swift
swift 03_NBody_Particle_Simulation.swift
swift 04_Raymarching_SDF.swift
swift 05_Compute_Image_Processing.swift
swift 06_ArgumentBuffers_IndirectDraw.swift
swift 07_TripleBuffering_Synchronization.swift
```

### Compiling to an optimized native binary:
```bash
swiftc -O 01_MatrixMultiplication_Tiled_SIMD.swift -o gemm_bench
./gemm_bench
```

---

## 🧠 Core Metal Architecture Concepts

### 1. Memory Address Spaces

```
+-------------------------------------------------------------+
| Device Memory (Global DRAM / Unified System RAM)             |
| - Address Space: `device` / `constant`                      |
| - Scope: Accessible by all threadgroups across the GPU      |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
| Threadgroup Shared Memory (On-Chip SRAM / L1 Cache)          |
| - Address Space: `threadgroup`                              |
| - Scope: Fast shared storage within 1 threadgroup (up to 32KB)|
| - Barrier: `threadgroup_barrier(mem_flags::mem_threadgroup)`|
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
| SIMD-Group / Execution Unit (32 Threads in Lockstep)        |
| - Intrinsics: `simd_shuffle_down`, `simd_sum`, `simd_broadcast`|
| - Communication without memory access!                      |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
| Thread Private Registers                                    |
| - Address Space: `thread` / local variables                 |
| - Scope: Highest bandwidth, lowest latency (0 cycles)       |
+-------------------------------------------------------------+
```

### 2. Apple Silicon TBDR (Tile-Based Deferred Rendering)
Unlike traditional desktop GPUs, Apple GPUs partition the screen into 16x16 or 32x32 tiles processed in ultra-high-bandwidth on-chip tile memory. Keeping working sets in threadgroup memory avoids round-trips to system memory.

### 3. CPU-GPU Triple Buffering Pattern
To achieve silky smooth 120 FPS without CPU or GPU waiting on each other:
1. Allocate dynamic uniform buffers with **3 ring slots** (size aligned to 256 bytes).
2. The CPU writes frame $N$ into slot `(N % 3)`.
3. The GPU renders frame $N-1$ from slot `((N-1) % 3)`.
4. The display presents frame $N-2$ from slot `((N-2) % 3)`.
5. Before CPU overwrites slot `(N % 3)`, it waits only if the GPU hasn't finished frame $N-3$.

---

## 🛠 Summary of Advanced MSL Techniques

- **Threadgroup Tiling**: Collaborative cache loads into `threadgroup float tile[DIM][DIM]` reduce DRAM read pressure by a factor of `TILE_DIM`.
- **SIMD Shuffles**: Exchanging data across lanes using `simd_shuffle_down(val, offset)` eliminates the need for threadgroup memory barriers.
- **Separable Convolutions**: Decomposing 2D filters into separate horizontal and vertical passes reduces computational complexity from $O(K^2)$ to $O(2K)$.
- **Argument Buffers**: Grouping textures, samplers, and buffers into MSL `struct` with `[[id(n)]]` drastically reduces CPU driver encode overhead and enables GPU-driven pipelines.
