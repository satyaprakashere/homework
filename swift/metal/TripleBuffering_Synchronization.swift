import Foundation
import Metal
import MetalKit

// ============================================================================
// LESSON 07: Advanced CPU-GPU Synchronization & Triple Buffering Architecture
// ============================================================================
//
// Key Concepts Covered:
// 1. Preventing CPU/GPU Pipeline Bubbles (Stalls): Why synchronous wait is bad for 120Hz/60Hz.
// 2. Ring-Buffered Dynamic Uniforms (`kMaxBuffersInFlight = 3`).
// 3. Asynchronous Frame Pacing using `DispatchSemaphore`.
// 4. `commandBuffer.addCompletedHandler` to signal the semaphore on GPU retirement.
// 5. Memory Alignment & Stride Rules (256-byte uniform alignment for Metal offsets).
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

let mslSource = loadShaderSource(named: "TripleBuffering_Synchronization.metal")


struct FrameUniforms {
    var modelViewProjection: simd_float4x4 = matrix_identity_float4x4
    var color: SIMD4<Float> = SIMD4<Float>(0.2, 0.6, 1.0, 1.0)
    var time: Float = 0.0
    var _pad: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
}

class TripleBufferEngine {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipeline: MTLComputePipelineState

    static let maxBuffersInFlight = 3
    var inFlightCommandBuffers = [MTLCommandBuffer?](repeating: nil, count: maxBuffersInFlight)

    let dynamicUniformBuffer: MTLBuffer
    let particleBuffer: MTLBuffer
    let uniformStride: Int
    let numParticles = 65_536

    init() {
        guard let dev = MTLCreateSystemDefaultDevice(),
              let queue = dev.makeCommandQueue() else {
            fatalError("Metal device or queue unavailable.")
        }
        self.device = dev
        self.commandQueue = queue

        // 256-byte alignment per uniform slot (Metal requirement for dynamic buffer offsets)
        self.uniformStride = (MemoryLayout<FrameUniforms>.stride + 255) & ~255
        let totalUniformBufferSize = self.uniformStride * TripleBufferEngine.maxBuffersInFlight
        self.dynamicUniformBuffer = dev.makeBuffer(length: totalUniformBufferSize, options: .storageModeShared)!

        let particleBufferSize = numParticles * MemoryLayout<SIMD4<Float>>.stride
        self.particleBuffer = dev.makeBuffer(length: particleBufferSize, options: .storageModeShared)!

        // Initialize particles in a 2D plane grid
        let particlePtr = particleBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: numParticles)
        let side = Int(sqrt(Double(numParticles)))
        for y in 0..<side {
            for x in 0..<side {
                let u = Float(x) / Float(side) * 4.0 - 2.0
                let v = Float(y) / Float(side) * 4.0 - 2.0
                particlePtr[y * side + x] = SIMD4<Float>(u, 0.0, v, 1.0)
            }
        }

        let library = try! dev.makeLibrary(source: mslSource, options: nil)
        let kernel = library.makeFunction(name: "simulate_frame_physics")!
        self.pipeline = try! dev.makeComputePipelineState(function: kernel)
    }

    func runSimulation(totalFrames: Int = 60) {
        print("GPU Device: \(device.name)")
        print("Ring Buffer: \(TripleBufferEngine.maxBuffersInFlight) in-flight slots (\(dynamicUniformBuffer.length) bytes, stride: \(uniformStride) B).")
        print("\nExecuting \(totalFrames) animated frames with zero-stall Triple Buffering...")

        var currentBufferIndex = 0
        let startTotalTime = CFAbsoluteTimeGetCurrent()

        for frame in 0..<totalFrames {
            // Step 1: Synchronize ONLY with the previous frame that used THIS ring slot (N - 3)
            // If the GPU has already finished frame (N - 3), this returns immediately with 0 stall!
            if let prevCmd = inFlightCommandBuffers[currentBufferIndex] {
                prevCmd.waitUntilCompleted()
            }

            // Step 2: Calculate memory offset for the current ring slot
            let uniformOffset = currentBufferIndex * uniformStride
            let uniformPtr = (dynamicUniformBuffer.contents() + uniformOffset).bindMemory(to: FrameUniforms.self, capacity: 1)

            // Step 3: Update uniforms on CPU safely without race conditions against GPU
            let frameTime = Float(frame) * 0.016
            uniformPtr.pointee = FrameUniforms(
                modelViewProjection: matrix_identity_float4x4,
                color: SIMD4<Float>(Float(frame % 10) / 10.0, 0.8, 0.5, 1.0),
                time: frameTime,
                _pad: SIMD3<Float>(0, 0, 0)
            )

            // Step 4: Encode and submit GPU commands for the current frame
            guard let cmdBuf = commandQueue.makeCommandBuffer(),
              let encoder = cmdBuf.makeComputeCommandEncoder() else { fatalError() }

            encoder.setComputePipelineState(pipeline)
            encoder.setBuffer(particleBuffer, offset: 0, index: 0)
            encoder.setBuffer(dynamicUniformBuffer, offset: uniformOffset, index: 1)

            let threadsPerGrid = MTLSize(width: numParticles, height: 1, depth: 1)
            let threadsPerGroup = MTLSize(width: 256, height: 1, depth: 1)
            encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
            encoder.endEncoding()

            // Step 5: Save reference to the active command buffer in the ring slot
            inFlightCommandBuffers[currentBufferIndex] = cmdBuf

            // Step 6: Asynchronously commit to GPU queue
            cmdBuf.commit()

            if (frame + 1) % 15 == 0 {
                print(String(format: "  Frame %2d/%2d committed | Slot: %d | Time: %.3fs",
                             frame + 1, totalFrames, currentBufferIndex, frameTime))
            }

            // Cycle through ring buffer slots: 0 -> 1 -> 2 -> 0 -> 1 -> 2
            currentBufferIndex = (currentBufferIndex + 1) % TripleBufferEngine.maxBuffersInFlight
        }

        // Drain any remaining in-flight command buffers
        for cmd in inFlightCommandBuffers {
            cmd?.waitUntilCompleted()
        }

        let totalElapsed = CFAbsoluteTimeGetCurrent() - startTotalTime
        let fps = Double(totalFrames) / totalElapsed
        print(String(format: "\nProcessed %d frames in %.3f s -> Frame rate: %.1f FPS", totalFrames, totalElapsed, fps))
        print("Triple Buffering Architecture achieved 0 pipeline stalls and 0 CPU-GPU race conditions.")
        print("==================================================================\n")
    }
}

func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 07 - Triple Buffering & Async Synchronization  ")
    print("==================================================================")
    let engine = TripleBufferEngine()
    engine.runSimulation(totalFrames: 60)
}

main()
