import Foundation
import Metal
import MetalKit

// ============================================================================
// LESSON 06: Modern Metal Argument Buffers & GPU Indirect Command Buffers
// ============================================================================
//
// Key Concepts Covered:
// 1. Argument Buffers: Grouping complex resource tables (Buffers, Textures, Constants)
//    into single structured buffer parameters (Tier 1 & Tier 2 Argument Buffers).
// 2. `MTLArgumentEncoder` reflection and encoding API in Swift.
// 3. Indirect Command Buffers (`MTLIndirectCommandBuffer` / ICB): GPU-driven rendering.
// 4. GPU-side frustum culling & dynamic draw parameter generation without CPU stalls.
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

let mslSource = loadShaderSource(named: "ArgumentBuffers_IndirectDraw.metal")


func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 06 - Argument Buffers & GPU-Driven Rendering   ")
    print("==================================================================")

    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else { fatalError() }

    print("GPU Device: \(device.name)")
    print("Argument Buffer Support Tier: \(device.argumentBuffersSupport)")

    let library = try! device.makeLibrary(source: mslSource, options: nil)

    // ------------------------------------------------------------------------
    // Part 1: Encoding Argument Buffers
    // ------------------------------------------------------------------------
    guard let fragFunc = library.makeFunction(name: "fragment_argbuffer") else { fatalError() }
    let materialArgEncoder = fragFunc.makeArgumentEncoder(bufferIndex: 0)

    let argBufferLength = materialArgEncoder.encodedLength
    let materialBuffer = device.makeBuffer(length: argBufferLength, options: .storageModeShared)!
    materialArgEncoder.setArgumentBuffer(materialBuffer, offset: 0)

    // Create a 64x64 checkerboard texture
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 64, height: 64, mipmapped: false)
    let texture = device.makeTexture(descriptor: texDesc)!
    var texData = [UInt32](repeating: 0xFFFFFFFF, count: 64 * 64)
    for y in 0..<64 {
        for x in 0..<64 {
            let isDark = (x / 8 + y / 8) % 2 == 0
            texData[y * 64 + x] = isDark ? 0xFF333333 : 0xFFEEEEEE
        }
    }
    texture.replace(region: MTLRegionMake2D(0, 0, 64, 64), mipmapLevel: 0, withBytes: texData, bytesPerRow: 64 * 4)

    // Create Sampler State
    let samplerDesc = MTLSamplerDescriptor()
    samplerDesc.minFilter = .linear
    samplerDesc.magFilter = .linear
    let sampler = device.makeSamplerState(descriptor: samplerDesc)!

    // Encode resources into the Argument Buffer
    materialArgEncoder.setTexture(texture, index: 0)
    materialArgEncoder.setSamplerState(sampler, index: 1)

    // Base Color (float4) & Roughness (float)
    let baseColor = SIMD4<Float>(0.9, 0.7, 0.2, 1.0)
    let roughness: Float = 0.35

    let colorPtr = materialArgEncoder.constantData(at: 2).bindMemory(to: SIMD4<Float>.self, capacity: 1)
    colorPtr.pointee = baseColor

    let roughnessPtr = materialArgEncoder.constantData(at: 3).bindMemory(to: Float.self, capacity: 1)
    roughnessPtr.pointee = roughness

    print(" Successfully encoded Material Argument Buffer (size: \(argBufferLength) bytes).")
    print(String(format: "  Encoded Texture: %dx%d, BaseColor: (%.2f, %.2f, %.2f), Roughness: %.2f",
                 texture.width, texture.height, baseColor.x, baseColor.y, baseColor.z, roughness))

    // ------------------------------------------------------------------------
    // Part 2: GPU-Driven Indirect Command Buffer (ICB)
    // ------------------------------------------------------------------------
    print("\n--- 2. GPU-DRIVEN INDIRECT DRAW EXECUTION ---")
    struct IndirectDrawArgs {
        var vertexCountPerInstance: UInt32 = 0
        var instanceCount: UInt32 = 0
        var startVertexLocation: UInt32 = 0
        var startInstanceLocation: UInt32 = 0
    }

    let indirectArgsBuffer = device.makeBuffer(length: MemoryLayout<IndirectDrawArgs>.stride, options: .storageModeShared)!
    let spheresBuffer = device.makeBuffer(length: 100 * MemoryLayout<SIMD4<Float>>.stride, options: .storageModeShared)!
    let spherePtr = spheresBuffer.contents().bindMemory(to: SIMD4<Float>.self, capacity: 100)
    for i in 0..<100 {
        spherePtr[i] = SIMD4<Float>(0, 0, 0, 1.5) // Positive radius = visible
    }

    let cullKernel = library.makeFunction(name: "gpu_cull_and_draw")!
    let cullPipeline = try! device.makeComputePipelineState(function: cullKernel)

    var totalInstances: UInt32 = 1000
    let cmdBuf = commandQueue.makeCommandBuffer()!
    let encoder = cmdBuf.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(cullPipeline)
    encoder.setBuffer(spheresBuffer, offset: 0, index: 0)
    encoder.setBuffer(indirectArgsBuffer, offset: 0, index: 1)
    encoder.setBytes(&totalInstances, length: MemoryLayout<UInt32>.stride, index: 2)
    encoder.dispatchThreads(MTLSize(width: 1, height: 1, depth: 1), threadsPerThreadgroup: MTLSize(width: 1, height: 1, depth: 1))
    encoder.endEncoding()

    cmdBuf.commit()
    cmdBuf.waitUntilCompleted()

    let drawArgs = indirectArgsBuffer.contents().bindMemory(to: IndirectDrawArgs.self, capacity: 1).pointee
    print(" GPU Compute Kernel generated Indirect Draw Command:")
    print("  Vertex Count / Instance : \(drawArgs.vertexCountPerInstance)")
    print("  Instance Count          : \(drawArgs.instanceCount)")
    print("  Start Vertex            : \(drawArgs.startVertexLocation)")
    print("  Start Instance          : \(drawArgs.startInstanceLocation)")
    print(" GPU-driven indirect draw configured successfully with 0 CPU draw call overhead.")
    print("==================================================================\n")
}

main()
