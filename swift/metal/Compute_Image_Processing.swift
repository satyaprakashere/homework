import Foundation
import Metal
import MetalKit

// ============================================================================
// LESSON 05: GPGPU Image Processing & 2D Convolutions in Metal
// ============================================================================
//
// Key Concepts Covered:
// 1. MTLTexture Read/Write Access (`access::read`, `access::write`, `access::sample`)
// 2. 2D Separable Convolution: Horizontal & Vertical Gaussian Blur (O(2K) vs O(K^2))
// 3. Sobel Edge Detection & Gradient Vector Calculation
// 4. Threadgroup 2D Shared Memory Caching with Apron/Halo Boundary Handling
// 5. Multi-Pass GPU Texture Ping-Ponging
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

let mslSource = loadShaderSource(named: "Compute_Image_Processing.metal")


func main() {
    print("==================================================================")
    print("   METAL ADVANCED: 05 - GPGPU Image Processing & Convolution      ")
    print("==================================================================")

    guard let device = MTLCreateSystemDefaultDevice(),
          let commandQueue = device.makeCommandQueue() else { fatalError() }

    print("GPU Device: \(device.name)")

    let width = 2048
    let height = 2048
    print("Image Dimensions: \(width)x\(height) (4.19 Megapixels)")

    let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
    texDesc.usage = [.shaderRead, .shaderWrite]
    texDesc.storageMode = .managed

    guard let texSource = device.makeTexture(descriptor: texDesc),
          let texPing = device.makeTexture(descriptor: texDesc),
          let texPong = device.makeTexture(descriptor: texDesc),
          let texEdges = device.makeTexture(descriptor: texDesc) else {
        fatalError("Texture creation failed.")
    }

    let library = try! device.makeLibrary(source: mslSource, options: nil)
    let funcPattern = library.makeFunction(name: "generate_pattern")!
    let funcSobel = library.makeFunction(name: "sobel_filter")!
    let funcBlur = library.makeFunction(name: "gaussian_blur_1d")!

    let pipePattern = try! device.makeComputePipelineState(function: funcPattern)
    let pipeSobel = try! device.makeComputePipelineState(function: funcSobel)
    let pipeBlur = try! device.makeComputePipelineState(function: funcBlur)

    let threadsPerGrid = MTLSize(width: width, height: height, depth: 1)
    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)

    // 1. Generate Pattern
    let cmd1 = commandQueue.makeCommandBuffer()!
    let enc1 = cmd1.makeComputeCommandEncoder()!
    enc1.setComputePipelineState(pipePattern)
    enc1.setTexture(texSource, index: 0)
    enc1.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    enc1.endEncoding()
    cmd1.commit()
    cmd1.waitUntilCompleted()
    print(" Pattern generated.")

    // 2. Sobel Filter
    let startSobel = CFAbsoluteTimeGetCurrent()
    let cmdSobel = commandQueue.makeCommandBuffer()!
    let encSobel = cmdSobel.makeComputeCommandEncoder()!
    encSobel.setComputePipelineState(pipeSobel)
    encSobel.setTexture(texSource, index: 0)
    encSobel.setTexture(texEdges, index: 1)
    encSobel.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
    encSobel.endEncoding()
    cmdSobel.commit()
    cmdSobel.waitUntilCompleted()
    let sobelElapsed = (CFAbsoluteTimeGetCurrent() - startSobel) * 1000.0
    print(String(format: " Sobel Edge Detection: %6.2f ms (%6.2f MPixels/sec)", sobelElapsed, Double(width * height) / sobelElapsed / 1000.0))

    // 3. Two-Pass Separable Gaussian Blur (Horizontal then Vertical)
    var dirHoriz = SIMD2<UInt32>(1, 0)
    var dirVert = SIMD2<UInt32>(0, 1)

    let startBlur = CFAbsoluteTimeGetCurrent()
    let cmdBlur = commandQueue.makeCommandBuffer()!
    let encBlur = cmdBlur.makeComputeCommandEncoder()!
    encBlur.setComputePipelineState(pipeBlur)

    // Pass 1: Horizontal Blur (texSource -> texPing)
    encBlur.setTexture(texSource, index: 0)
    encBlur.setTexture(texPing, index: 1)
    encBlur.setBytes(&dirHoriz, length: MemoryLayout<SIMD2<UInt32>>.stride, index: 0)
    encBlur.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)

    // Pass 2: Vertical Blur (texPing -> texPong)
    encBlur.setTexture(texPing, index: 0)
    encBlur.setTexture(texPong, index: 1)
    encBlur.setBytes(&dirVert, length: MemoryLayout<SIMD2<UInt32>>.stride, index: 0)
    encBlur.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)

    encBlur.endEncoding()
    cmdBlur.commit()
    cmdBlur.waitUntilCompleted()
    let blurElapsed = (CFAbsoluteTimeGetCurrent() - startBlur) * 1000.0
    print(String(format: " 2-Pass Separable Gaussian Blur: %6.2f ms (%6.2f MPixels/sec)", blurElapsed, Double(width * height) / blurElapsed / 1000.0))

    print("\nComparison: Separable 2-Pass convolution requires 2*K = 10 samples/pixel.")
    print("Non-separable naive 2D blur would require K^2 = 81 samples/pixel (8.1x more bandwidth!).")
    print("==================================================================\n")
}

main()
