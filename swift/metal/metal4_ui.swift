import SwiftUI
import MetalKit

// MARK: - 1. Shader Library Loader
func loadShaderLibrary(device: any MTLDevice, compiler: any MTL4Compiler) throws -> any MTLLibrary {
    let candidateURLs: [URL] = [
        Bundle.main.url(forResource: "Shaders", withExtension: "metallib"),
        Bundle.main.url(forResource: "Shaders", withExtension: "metal"),
        URL(fileURLWithPath: "Shaders.metallib"),
        URL(fileURLWithPath: "Shaders.metal"),
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Shaders.metal")
    ].compactMap { $0 }
    
    let fileManager = FileManager.default
    for url in candidateURLs where fileManager.fileExists(atPath: url.path) {
        if url.pathExtension == "metallib" {
            return try device.makeLibrary(URL: url)
        } else if let source = try? String(contentsOf: url, encoding: .utf8) {
            let libDesc = MTL4LibraryDescriptor()
            libDesc.source = source
            let compileOptions = MTLCompileOptions()
            compileOptions.languageVersion = .version4_0
            libDesc.options = compileOptions
            return try compiler.makeLibrary(descriptor: libDesc)
        }
    }
    
    if let defaultLib = device.makeDefaultLibrary() {
        return defaultLib
    }
    
    throw NSError(domain: "RendererError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find or load Shaders.metal"])
}

// MARK: - 2. Data Types
struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

// MARK: - 3. Metal 4 Renderer
class Renderer: NSObject, MTKViewDelegate {
    var device: (any MTLDevice)!
    var commandQueue: (any MTL4CommandQueue)!
    var commandAllocator: (any MTL4CommandAllocator)!
    var commandBuffer: (any MTL4CommandBuffer)!
    var pipelineState: (any MTLRenderPipelineState)!
    var vertexBuffer: (any MTLBuffer)!
    var argumentTable: (any MTL4ArgumentTable)!

    let vertices: [Vertex] = [
        Vertex(position: [ 0.0,  0.5, 0.0], color: [1, 0, 0, 1]),
        Vertex(position: [-0.5, -0.5, 0.0], color: [0, 1, 0, 1]),
        Vertex(position: [ 0.5, -0.5, 0.0], color: [0, 0, 1, 1])
    ]

    init?(metalView: MTKView) {
        super.init()
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.device = device
        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        metalView.delegate = self

        guard let commandQueue = device.makeMTL4CommandQueue(),
              let commandAllocator = device.makeCommandAllocator(),
              let commandBuffer = device.makeCommandBuffer() else {
            return nil
        }
        self.commandQueue = commandQueue
        self.commandAllocator = commandAllocator
        self.commandBuffer = commandBuffer

        do {
            let compiler = try device.makeCompiler(descriptor: MTL4CompilerDescriptor())
            let library = try loadShaderLibrary(device: device, compiler: compiler)

            let vertexFunctionDesc = MTL4LibraryFunctionDescriptor()
            vertexFunctionDesc.library = library
            vertexFunctionDesc.name = "vertexShader"

            let fragmentFunctionDesc = MTL4LibraryFunctionDescriptor()
            fragmentFunctionDesc.library = library
            fragmentFunctionDesc.name = "fragmentShader"

            let descriptor = MTL4RenderPipelineDescriptor()
            descriptor.vertexFunctionDescriptor = vertexFunctionDesc
            descriptor.fragmentFunctionDescriptor = fragmentFunctionDesc
            descriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float3
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[1].format = .float4
            vertexDescriptor.attributes[1].offset = 16
            vertexDescriptor.attributes[1].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride

            descriptor.vertexDescriptor = vertexDescriptor
            pipelineState = try compiler.makeRenderPipelineState(descriptor: descriptor)

            let dataSize = vertices.count * MemoryLayout<Vertex>.stride
            guard let buffer = device.makeBuffer(bytes: vertices, length: dataSize, options: []) else {
                return nil
            }
            vertexBuffer = buffer

            let tableDescriptor = MTL4ArgumentTableDescriptor()
            tableDescriptor.maxBufferBindCount = 1
            argumentTable = try device.makeArgumentTable(descriptor: tableDescriptor)
            argumentTable.setAddress(buffer.gpuAddress, index: 0)
        } catch {
            print("Setup failed: \(error)")
            return nil
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
              let drawable = view.currentDrawable else { return }

        commandAllocator.reset()
        commandBuffer.beginCommandBuffer(allocator: commandAllocator)

        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            commandBuffer.endCommandBuffer()
            return
        }

        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        renderEncoder.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()

        commandBuffer.endCommandBuffer()

        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)
        drawable.present()
    }
}

// MARK: - 4. SwiftUI Bridge (NSViewRepresentable)
struct MetalView: NSViewRepresentable {
    // We use a Coordinator to keep a strong reference to the Renderer.
    // MTKView holds its delegate weakly, so if we don't retain it here, it gets deallocated.
    class Coordinator {
        var renderer: Renderer?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let mtkView = MTKView()
        // Instantiate the Renderer and store it in the coordinator
        context.coordinator.renderer = Renderer(metalView: mtkView)
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        // No updates needed for a static triangle
    }
}

// MARK: - 5. SwiftUI Views & App
struct ContentView: View {
    var body: some View {
        MetalView()
            // Set initial window dimensions similar to your AppKit setup
            .frame(minWidth: 800, minHeight: 600)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    var body: some Scene {
        WindowGroup("Metal Command Line Example") {
            ContentView()
        }
    }
}

// MARK: - 6. Entry Point
MyApp.main()
