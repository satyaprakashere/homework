import Foundation
import Metal
import MetalKit

// ============================================================================
// LESSON 01: High-Performance GPGPU General Matrix Multiplication (GEMM)
// ============================================================================
//
// Key Concepts Covered:
// 1. Memory Coalescing & Global Memory Access Latency
// 2. Threadgroup Shared Memory (Tiling) to cache matrix blocks in on-chip L1
// 3. Apple Silicon SIMD-Group Matrix Operations (`simdgroup_matrix`) for hardware acceleration
// 4. Threadgroup Synchronization (`threadgroup_barrier`)
// 5. Profiling GPU Throughput (GFLOPS) vs CPU Naive Implementation
// ============================================================================

func loadShaderSource(named name: String) -> String {
    let candidateURLs: [URL] = [
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent(name),
        URL(fileURLWithPath: name),
        Bundle.main.url(forResource: (name as NSString).deletingPathExtension, withExtension: (name as NSString).pathExtension)
    ].compactMap { $0 }

    for url in candidateURLs {
        if let source = try? String(contentsOf: url, encoding: .utf8) {
            return source
        }
    }
    fatalError("Could not find or load shader file: \(name)")
}

let mslSource = loadShaderSource(named: "MatrixMultiplication_Tiled_SIMD.metal")


func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 01 - Matrix Multiplication (GEMM) Benchmark    ")
    print("==================================================================")

    guard let device = MTLCreateSystemDefaultDevice() else {
        print("Error: Metal is not supported on this device.")
        return
    }
    print("GPU Device: \(device.name)")
    guard let commandQueue = device.makeCommandQueue() else { fatalError() }

    // Dimensions: M x K * K x N = M x N
    let M: Int = 512
    let N: Int = 512
    let K: Int = 512
    var dims = SIMD3<UInt32>(UInt32(M), UInt32(N), UInt32(K))

    let countA = M * K
    let countB = K * N
    let countC = M * N

    let byteSizeA = countA * MemoryLayout<Float>.stride
    let byteSizeB = countB * MemoryLayout<Float>.stride
    let byteSizeC = countC * MemoryLayout<Float>.stride

    guard let bufferA = device.makeBuffer(length: byteSizeA, options: .storageModeShared),
          let bufferB = device.makeBuffer(length: byteSizeB, options: .storageModeShared),
          let bufferC = device.makeBuffer(length: byteSizeC, options: .storageModeShared),
          let bufferDims = device.makeBuffer(bytes: &dims, length: MemoryLayout<SIMD3<UInt32>>.stride, options: .storageModeShared)
    else {
        fatalError("Failed to allocate Metal buffers.")
    }

    // Initialize matrices with reproducible pseudo-random values
    let ptrA = bufferA.contents().bindMemory(to: Float.self, capacity: countA)
    let ptrB = bufferB.contents().bindMemory(to: Float.self, capacity: countB)
    for i in 0..<countA { ptrA[i] = Float(i % 17) * 0.05 }
    for i in 0..<countB { ptrB[i] = Float(i % 13) * 0.05 }

    // Compile Metal Library
    let library: MTLLibrary
    do {
        library = try device.makeLibrary(source: mslSource, options: nil)
    } catch {
        print("Shader compilation error: \(error)")
        return
    }

    guard let funcNaive = library.makeFunction(name: "gemm_naive"),
          let funcTiled = library.makeFunction(name: "gemm_tiled"),
          let funcRegBlocked = library.makeFunction(name: "gemm_register_blocked") else {
        fatalError("Could not find shader functions.")
    }

    let pipelineNaive = try! device.makeComputePipelineState(function: funcNaive)
    let pipelineTiled = try! device.makeComputePipelineState(function: funcTiled)
    let pipelineRegBlocked = try! device.makeComputePipelineState(function: funcRegBlocked)

    // Helper runner
    func runKernel(name: String, pipeline: MTLComputePipelineState, configureEncoder: (MTLComputeCommandEncoder) -> Void) -> Double {
        // Clear destination buffer
        memset(bufferC.contents(), 0, byteSizeC)

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(pipeline)
        encoder.setBuffer(bufferA, offset: 0, index: 0)
        encoder.setBuffer(bufferB, offset: 0, index: 1)
        encoder.setBuffer(bufferC, offset: 0, index: 2)
        encoder.setBuffer(bufferDims, offset: 0, index: 3)
        configureEncoder(encoder)
        encoder.endEncoding()

        let start = CFAbsoluteTimeGetCurrent()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

        let operations = 2.0 * Double(M) * Double(N) * Double(K)
        let gflops = (operations / (elapsedMs / 1000.0)) / 1e9

        let ptrC = bufferC.contents().bindMemory(to: Float.self, capacity: countC)
        let paddedName = name.padding(toLength: 26, withPad: " ", startingAt: 0)
        print(String(format: "  %@ | Time: %7.2f ms | Performance: %7.2f GFLOPS | C[0,0]=%.4f C[N/2,N/2]=%.4f",
                     paddedName, elapsedMs, gflops, ptrC[0], ptrC[(M/2) * N + (N/2)]))
        return elapsedMs
    }

    print("\nBenchmarking Matrix Multiplication (\(M)x\(K) * \(K)x\(N))...")
    print("---------------------------------------------------------------------------------------------------")

    // 1. Naive GPU
    _ = runKernel(name: "1. GPU Naive", pipeline: pipelineNaive) { encoder in
        let threadsPerGrid = MTLSize(width: N, height: M, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    // 2. Tiled GPU (Threadgroup Memory)
    _ = runKernel(name: "2. GPU Tiled (16x16)", pipeline: pipelineTiled) { encoder in
        let threadsPerGrid = MTLSize(width: N, height: M, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    // 3. Register Blocked GPU (2D Block Tiling + Registers)
    _ = runKernel(name: "3. GPU 2D Register Block", pipeline: pipelineRegBlocked) { encoder in
        // Grid is dispatched in blocks of (64, 64)
        let threadgroups = MTLSize(width: (N + 63) / 64, height: (M + 63) / 64, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 16, height: 16, depth: 1)
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    // 4. CPU Reference (on subset verification)
    print("\nVerifying with CPU Reference (first 4x4 block)...")
    var cpuCheckCorrect = true
    let ptrC = bufferC.contents().bindMemory(to: Float.self, capacity: countC)
    for r in 0..<4 {
        for c in 0..<4 {
            var sum: Float = 0
            for k in 0..<K {
                sum += ptrA[r * K + k] * ptrB[k * N + c]
            }
            let gpuVal = ptrC[r * N + c]
            if abs(sum - gpuVal) > 1e-2 {
                print("Mismatch at (\(r),\(c)): CPU = \(sum), GPU = \(gpuVal)")
                cpuCheckCorrect = false
            }
        }
    }

    if cpuCheckCorrect {
        print(" Verification PASSED! GPU results match CPU reference.")
    } else {
        print(" Verification FAILED.")
    }
    print("==================================================================\n")
}

main()
