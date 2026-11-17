import Foundation
import Metal

// ============================================================================
// LESSON 02: Parallel Reduction & Prefix Sum (Scan) in Metal
// ============================================================================
//
// Key Concepts Covered:
// 1. SIMD-Level Intrinsics: `simd_shuffle_down` & `simd_sum` (zero shared memory cost)
// 2. Threadgroup-Level Hierarchical Tree Reduction (Shared Memory + Barriers)
// 3. Multi-Pass Dispatch: Reducing arrays larger than a single threadgroup
// 4. Blelloch Parallel Exclusive Prefix Sum (Up-Sweep & Down-Sweep)
// 5. Verification against CPU ground truth for 4,000,000+ elements
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

let mslSource = loadShaderSource(named: "ParallelReduction_PrefixSum.metal")


func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 02 - Parallel Reduction & Prefix Sum (Scan)    ")
    print("==================================================================")

    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else {
        fatalError("Metal device or command queue unavailable.")
    }
    print("GPU Device: \(device.name)")

    let library: MTLLibrary
    do {
        library = try device.makeLibrary(source: mslSource, options: nil)
    } catch {
        print("Shader compilation error: \(error)")
        return
    }

    guard let funcReduce = library.makeFunction(name: "reduce_sum_stage1"),
          let funcScan = library.makeFunction(name: "blelloch_scan_exclusive") else {
        fatalError("Missing kernel functions.")
    }

    let pipelineReduce = try! device.makeComputePipelineState(function: funcReduce)
    let pipelineScan = try! device.makeComputePipelineState(function: funcScan)

    // ------------------------------------------------------------------------
    // Part 1: High-Performance Parallel Reduction (4 Million Elements)
    // ------------------------------------------------------------------------
    let N = 4_194_304 // 4M floats
    print("\n--- 1. PARALLEL REDUCTION BENCHMARK (\(N) elements) ---")

    let byteSize = N * MemoryLayout<Float>.stride
    guard let inputBuffer = device.makeBuffer(length: byteSize, options: .storageModeShared) else { fatalError() }

    let inputPtr = inputBuffer.contents().bindMemory(to: Float.self, capacity: N)
    var expectedSum: Double = 0
    for i in 0..<N {
        let val = Float((i % 10) + 1) * 0.25
        inputPtr[i] = val
        expectedSum += Double(val)
    }

    let threadsPerGroup = 256
    let numGroups = (N + (threadsPerGroup * 2) - 1) / (threadsPerGroup * 2)
    let partialSumsBuffer = device.makeBuffer(length: numGroups * MemoryLayout<Float>.stride, options: .storageModeShared)!
    var countUInt = UInt32(N)

    let startGPU = CFAbsoluteTimeGetCurrent()
    let cmdBuf = commandQueue.makeCommandBuffer()!
    let encoder = cmdBuf.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(pipelineReduce)
    encoder.setBuffer(inputBuffer, offset: 0, index: 0)
    encoder.setBuffer(partialSumsBuffer, offset: 0, index: 1)
    encoder.setBytes(&countUInt, length: MemoryLayout<UInt32>.stride, index: 2)

    encoder.dispatchThreadgroups(MTLSize(width: numGroups, height: 1, depth: 1),
                                 threadsPerThreadgroup: MTLSize(width: threadsPerGroup, height: 1, depth: 1))
    encoder.endEncoding()
    cmdBuf.commit()
    cmdBuf.waitUntilCompleted()

    // Host finishes the small partial sum array (numGroups is ~8192)
    let partialPtr = partialSumsBuffer.contents().bindMemory(to: Float.self, capacity: numGroups)
    var gpuTotalSum: Double = 0
    for i in 0..<numGroups {
        gpuTotalSum += Double(partialPtr[i])
    }
    let gpuElapsedMs = (CFAbsoluteTimeGetCurrent() - startGPU) * 1000.0
    let bandwidthGBs = (Double(byteSize) / (gpuElapsedMs / 1000.0)) / 1e9

    print(String(format: "  GPU Sum: %.4f | Expected: %.4f", gpuTotalSum, expectedSum))
    print(String(format: "  Time: %.3f ms | Bandwidth: %.2f GB/s", gpuElapsedMs, bandwidthGBs))
    let diff = abs(gpuTotalSum - expectedSum)
    let relativeDiff = diff / expectedSum
    print(String(format: "  Absolute Diff: %.2f | Relative Diff: %.6f%%", diff, relativeDiff * 100))
    print("  Reduction Status: \(relativeDiff < 1e-4 ? "PASSED (within float32 precision)" : "FAILED")")

    // ------------------------------------------------------------------------
    // Part 2: Parallel Exclusive Prefix Sum (Blelloch Scan)
    // ------------------------------------------------------------------------
    let scanCount = 512 // 1 threadgroup block (512 elements)
    print("\n--- 2. BLELLOCH EXCLUSIVE PREFIX SUM (SCAN) (\(scanCount) elements) ---")

    let scanBuffer = device.makeBuffer(length: scanCount * MemoryLayout<Float>.stride, options: .storageModeShared)!
    let scanPtr = scanBuffer.contents().bindMemory(to: Float.self, capacity: scanCount)
    var cpuInput = [Float](repeating: 0, count: scanCount)
    for i in 0..<scanCount {
        cpuInput[i] = Float(i % 5 + 1)
        scanPtr[i] = cpuInput[i]
    }

    var scanN = UInt32(scanCount)
    let scanCmdBuf = commandQueue.makeCommandBuffer()!
    let scanEncoder = scanCmdBuf.makeComputeCommandEncoder()!
    scanEncoder.setComputePipelineState(pipelineScan)
    scanEncoder.setBuffer(scanBuffer, offset: 0, index: 0)
    scanEncoder.setBuffer(scanBuffer, offset: 0, index: 1) // null block sum for single group
    scanEncoder.setBytes(&scanN, length: MemoryLayout<UInt32>.stride, index: 2)

    scanEncoder.dispatchThreadgroups(MTLSize(width: 1, height: 1, depth: 1),
                                     threadsPerThreadgroup: MTLSize(width: scanCount / 2, height: 1, depth: 1))
    scanEncoder.endEncoding()
    scanCmdBuf.commit()
    scanCmdBuf.waitUntilCompleted()

    // CPU validation of Exclusive Scan: out[0] = 0, out[i] = sum(in[0..<i])
    var cpuPrefixSum: Float = 0
    var scanPassed = true
    for i in 0..<scanCount {
        let expected = cpuPrefixSum
        let actual = scanPtr[i]
        cpuPrefixSum += cpuInput[i]

        if i < 8 {
            print(String(format: "  Index %2d: Input = %3.1f | Exclusive Scan = %5.1f (Expected: %5.1f)",
                         i, cpuInput[i], actual, expected))
        }
        if abs(actual - expected) > 1e-4 {
            scanPassed = false
        }
    }
    print("  ...")
    print("  Scan Verification: \(scanPassed ? "PASSED" : "FAILED")")
    print("==================================================================\n")
}

main()
