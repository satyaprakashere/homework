import Foundation
import Metal
import MetalKit
#if canImport(AppKit)
import AppKit
#endif

// ============================================================================
// LESSON 03: GPGPU N-Body Particle Simulation (Compute-to-Render Pipeline)
// ============================================================================
//
// Key Concepts Covered:
// 1. O(N^2) All-Pairs Gravitational Compute Pipeline with Epsilon Softening
// 2. Threadgroup Tiled Acceleration for Particle-Particle interactions
// 3. Compute-to-Render Zero-Copy Buffer Sharing (Compute writes, Rasterizer reads)
// 4. Ping-Pong Double Buffering of Physics State
// 5. Point Sprites & Instanced Rendering in Metal Shading Language
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

let mslSource = loadShaderSource(named: "NBody_Particle_Simulation.metal")


struct Particle {
    var position: SIMD4<Float>
    var velocity: SIMD4<Float>
}

struct Uniforms {
    var dt: Float = 0.016
    var softening: Float = 0.1
    var damping: Float = 0.999
    var numParticles: UInt32
}

func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 03 - GPGPU N-Body Particle Simulation          ")
    print("==================================================================")

    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else { fatalError() }

    print("GPU Device: \(device.name)")

    let numParticles = 16_384 // 16K particles (16,384^2 = 268 Million body interactions/frame)
    let bufferSize = numParticles * MemoryLayout<Particle>.stride
    print("Particles: \(numParticles) | All-Pairs Interactions/Step: \(numParticles * numParticles / 1_000_000) Million")

    guard let bufferA = device.makeBuffer(length: bufferSize, options: .storageModeShared),
          let bufferB = device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
        fatalError("Buffer allocation failed.")
    }

    // Initialize particles into a rotating disk/galaxy formation
    let ptrA = bufferA.contents().bindMemory(to: Particle.self, capacity: numParticles)
    for i in 0..<numParticles {
        let angle = Float(i) / Float(numParticles) * 2.0 * .pi * 8.0 + Float.random(in: -0.2...0.2)
        let radius = sqrt(Float.random(in: 0.1...6.0))
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        let z = Float.random(in: -0.2...0.2)
        let mass: Float = (i == 0) ? 500.0 : 1.0 // Central supermassive body + orbiting bodies

        // Circular orbital velocity v = sqrt(G*M / r)
        let speed = (i == 0) ? 0.0 : sqrt(500.0 / max(radius, 0.5)) * 0.1
        let vx = -sin(angle) * speed
        let vy = cos(angle) * speed

        ptrA[i] = Particle(
            position: SIMD4<Float>(x, y, z, mass),
            velocity: SIMD4<Float>(vx, vy, 0.0, 0.0)
        )
    }

    let library = try! device.makeLibrary(source: mslSource, options: nil)
    let computeFunc = library.makeFunction(name: "nbody_simulation_tiled")!
    let pipelineCompute = try! device.makeComputePipelineState(function: computeFunc)

    var uniforms = Uniforms(dt: 0.01, softening: 0.05, damping: 0.9995, numParticles: UInt32(numParticles))
    let uniformsBuffer = device.makeBuffer(bytes: &uniforms, length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)!

    // Simulate 50 steps on the GPU using Ping-Pong double buffering
    print("\nExecuting 50 GPU Physics Simulation Steps (Ping-Pong buffers)...")
    let startSim = CFAbsoluteTimeGetCurrent()
    var readBuffer = bufferA
    var writeBuffer = bufferB

    let totalSteps = 50
    for step in 0..<totalSteps {
        let cmdBuf = commandQueue.makeCommandBuffer()!
        let encoder = cmdBuf.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(pipelineCompute)
        encoder.setBuffer(readBuffer, offset: 0, index: 0)
        encoder.setBuffer(writeBuffer, offset: 0, index: 1)
        encoder.setBuffer(uniformsBuffer, offset: 0, index: 2)

        let threadsPerGroup = MTLSize(width: 256, height: 1, depth: 1)
        let threadgroups = MTLSize(width: (numParticles + 255) / 256, height: 1, depth: 1)
        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()

        cmdBuf.commit()
        cmdBuf.waitUntilCompleted()

        // Swap ping-pong buffers
        swap(&readBuffer, &writeBuffer)

        if (step + 1) % 10 == 0 {
            let p0 = readBuffer.contents().bindMemory(to: Particle.self, capacity: numParticles)[0]
            let p1 = readBuffer.contents().bindMemory(to: Particle.self, capacity: numParticles)[1]
            print(String(format: "  Step %2d/50 complete | Center: (%.2f, %.2f) | Orbit Particle: (%.2f, %.2f)",
                         step + 1, p0.position.x, p0.position.y, p1.position.x, p1.position.y))
        }
    }

    let elapsed = CFAbsoluteTimeGetCurrent() - startSim
    let stepsPerSec = Double(totalSteps) / elapsed
    let gflops = (Double(totalSteps) * Double(numParticles) * Double(numParticles) * 20.0) / elapsed / 1e9
    print(String(format: "\nSimulation Performance: %.2f FPS (Physics Steps/Sec) | %.2f GFLOPS Equivalent", stepsPerSec, gflops))
    print("Zero-Copy Pipeline: The resulting buffer is immediately ready for vertex rendering without CPU copies.")
    print("==================================================================\n")
}

main()
