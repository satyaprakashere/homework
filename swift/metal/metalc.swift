import Foundation
import Metal

// Define the kernel logic in Metal Shading Language (MSL)
let shaderSource = """
#include <metal_stdlib>
using namespace metal;

kernel void addVectors(const device float* a [[ buffer(0) ]],
                       const device float* b [[ buffer(1) ]],
                       device float* c  [[ buffer(2) ]],
                       uint gid [[ thread_position_in_grid ]]) {
    c[gid] = a[gid] + b[gid];
}
"""

//kernelFn addVectors(A, B, C float[], id tp_grid)
//  C[id] = A[id] + B[id];
//}

let count    = 1_000_000
let byteSize = count * MemoryLayout<Float>.stride

// 1. Get GPU Device and Command Queue
guard let device       = MTLCreateSystemDefaultDevice(),
      let commandQueue = device.makeCommandQueue() else { fatalError() }

// 2. Allocate Unified Memory Buffers (Shared between CPU & GPU)
let bufferA = device.makeBuffer(length: byteSize, options: .storageModeShared)!
let bufferB = device.makeBuffer(length: byteSize, options: .storageModeShared)!
let bufferC = device.makeBuffer(length: byteSize, options: .storageModeShared)!

// Populate inputs using CPU pointers directly
let ptrA = bufferA.contents().bindMemory(to: Float.self, capacity: count)
let ptrB = bufferB.contents().bindMemory(to: Float.self, capacity: count)
for i in 0..<count {
    ptrA[i] = 1.0
    ptrB[i] = 2.0
}

// 3. Compile MSL Shader & Create Pipeline
let library        = try! device.makeLibrary(source: shaderSource, options: nil)
let kernelFunction = library.makeFunction(name: "addVectors")
let pipelineState  = try! device.makeComputePipelineState(function: kernelFunction!)

// 4. Encode & Dispatch Work
let commandBuffer = commandQueue.makeCommandBuffer()!
let encoder = commandBuffer.makeComputeCommandEncoder()!

encoder.setComputePipelineState(pipelineState)
encoder.setBuffer(bufferA, offset: 0, index: 0)
encoder.setBuffer(bufferB, offset: 0, index: 1)
encoder.setBuffer(bufferC, offset: 0, index: 2)

// Set grid size & threadgroup dimensions
let gridSize = MTLSize(width: count, height: 1, depth: 1)
let threadgroupSize = MTLSize(width: pipelineState.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)

encoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
encoder.endEncoding()

// 5. Submit to GPU and wait
commandBuffer.commit()
commandBuffer.waitUntilCompleted()

// 6. Read Results directly on CPU
let ptrC = bufferC.contents().bindMemory(to: Float.self, capacity: count)
print("C[0] = \(ptrC[0])") // Output: 3.0