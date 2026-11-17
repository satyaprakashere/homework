import Foundation
import Metal
import MetalKit

// ----------------------------------------------------------------------------------------==========
// LESSON 04: Signed Distance Field (SDF) Raymarching in Metal
// ----------------------------------------------------------------------------------------==========
//
// Key Concepts Covered:
// 1. Raymarching / Sphere Tracing numerical root-finding algorithm
// 2. Exact Primitive SDFs: Sphere, Torus, Rounded Box, Infinite Plane
// 3. Smooth Boolean Constructive Solid Geometry (CSG Smooth Minimum `smin`)
// 4. Numerical Gradient for Accurate Normal Calculation
// 5. Soft Shadow Penumbra Approximation & Ambient Occlusion (AO)
// 6. Direct Compute Texture Write (`texture2d<float, access::write>`)
// ----------------------------------------------------------------------------------------==========

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

let mslSource = loadShaderSource(named: "Raymarching_SDF.metal")


struct CameraUniform {
    var position: SIMD3<Float> = SIMD3<Float>(0.0, 2.5, -4.5)
    var target: SIMD3<Float> = SIMD3<Float>(0.0, 0.5, 0.0)
    var fov: Float = 60.0
    var _pad: Float = 0.0
    var resolution: SIMD2<Float>
}

func main() {
    print("----------------------------------------------------------------------------------------")
    print("   METAL ADVANCED: 04 - Volumetric SDF Raymarching Shader         ")
    print("----------------------------------------------------------------------------------------")

    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else { fatalError() }

    print("GPU Device: \(device.name)")

    let width = 1280
    let height = 720
    print("Target Render Resolution: \(width)x\(height) (720p HD)")

    // Allocate Output Texture (MTLTextureUsageShaderWrite)
    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
    texDesc.usage = [.shaderWrite, .shaderRead]
    texDesc.storageMode = .shared
    guard let outTexture = device.makeTexture(descriptor: texDesc) else { fatalError("Texture allocation failed.") }

    var camera = CameraUniform(
        position: SIMD3<Float>(0.0, 2.5, -4.5),
        target: SIMD3<Float>(0.0, 0.3, 0.0),
        fov: 60.0,
        _pad: 0.0,
        resolution: SIMD2<Float>(Float(width), Float(height))
    )
    let cameraBuffer = device.makeBuffer(bytes: &camera, length: MemoryLayout<CameraUniform>.stride, options: .storageModeShared)!

    let library = try! device.makeLibrary(source: mslSource, options: nil)
    let kernel = library.makeFunction(name: "raymarch_kernel")!
    let pipeline = try! device.makeComputePipelineState(function: kernel)

    print("\nDispatching SDF Raymarching compute passes...")
    let start = CFAbsoluteTimeGetCurrent()

    let cmdBuf = commandQueue.makeCommandBuffer()!
    let encoder = cmdBuf.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(pipeline)
    encoder.setTexture(outTexture, index: 0)
    encoder.setBuffer(cameraBuffer, offset: 0, index: 0)

    let threadsPerGrid = MTLSize(width: width, height: height, depth: 1)
    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
    encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    encoder.endEncoding()

    // Synchronize managed texture memory for CPU reading
    let blit = cmdBuf.makeBlitCommandEncoder()!
    // blit.synchronize(resource: outTexture)
    blit.endEncoding()

    cmdBuf.commit()
    cmdBuf.waitUntilCompleted()

    let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
    let rayCount = width * height
    let mraysSec = (Double(rayCount) / (elapsedMs / 1000.0)) / 1e6

    print(String(format: "Render Time: %7.2f ms | Throughput: %7.2f Million primary rays/sec", elapsedMs, mraysSec))

    // Save image to PPM file for immediate viewing and testing
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    var rawPixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    let region = MTLRegionMake2D(0, 0, width, height)
    outTexture.getBytes(&rawPixels, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

    let ppmPath = "/Users/prakash/Documents/homework/swift/metal/raymarch_output.ppm"
    var ppmData = "P3\n\(width) \(height)\n255\n"
    for y in 0..<height {
        for x in 0..<width {
            let idx = (y * width + x) * 4
            let r = rawPixels[idx]
            let g = rawPixels[idx + 1]
            let b = rawPixels[idx + 2]
            ppmData += "\(r) \(g) \(b) "
        }
        ppmData += "\n"
    }

    try? ppmData.write(toFile: ppmPath, atomically: true, encoding: .ascii)
    print("Saved rendered frame to: \(ppmPath)")
    print("----------------------------------------------------------------------------------------\n")
}

main()
