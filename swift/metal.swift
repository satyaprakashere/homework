import Cocoa
import Metal
import MetalKit

// MARK: - 1. Embedded Shaders
let shaderSource = """
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
};

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData vertexShader(uint vertexID [[vertex_id]],
                                   constant VertexIn *vertices [[buffer(0)]]) {
    RasterizerData out;
    out.position = float4(vertices[vertexID].position, 1.0);
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 fragmentShader(RasterizerData in [[stage_in]]) {
    return in.color;
}
"""

// MARK: - 2. Data Types
struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

// MARK: - 3. Renderer
class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var vertexBuffer: MTLBuffer!
    
    let vertices: [Vertex] = [
        Vertex(position: [ 0.0,  0.5, 0.0], color: [1, 0, 0, 1]),
        Vertex(position: [-0.5, -0.5, 0.0], color: [0, 1, 0, 1]),
        Vertex(position: [ 0.5, -0.5, 0.0], color: [0, 0, 1, 1])
    ]
    
    init?(metalView: MTKView) {
        super.init()
      // guard let device = MTLCreateSystemDefaultDevice() orElse return
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.device = device
        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        metalView.delegate = self
        
        commandQueue = device.makeCommandQueue()
        
        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            let vertexDescriptor = MTLVertexDescriptor()
            vertexDescriptor.attributes[0].format = .float3
            vertexDescriptor.attributes[0].offset = 0
            vertexDescriptor.attributes[0].bufferIndex = 0
            vertexDescriptor.attributes[1].format = .float4
            vertexDescriptor.attributes[1].offset = 16 // 16 bytes (float3 + padding)
            vertexDescriptor.attributes[1].bufferIndex = 0
            vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
            
            descriptor.vertexDescriptor = vertexDescriptor
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
            
            let dataSize = vertices.count * MemoryLayout<Vertex>.stride
            vertexBuffer = device.makeBuffer(bytes: vertices, length: dataSize, options: [])
        } catch {
            print("Setup failed: \(error)")
            return nil
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - 4. Application Setup (AppKit)
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var renderer: Renderer!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowSize = NSMakeRect(0, 0, 800, 600)
        window = NSWindow(contentRect: windowSize,
                          styleMask: [.titled, .closable, .resizable, .miniaturizable],
                          backing: .buffered,
                          defer: false)
        window.title = "Metal Command Line Example"
        window.center()
        
        let mtkView = MTKView(frame: windowSize)
        renderer = Renderer(metalView: mtkView)
        window.contentView = mtkView
        window.makeKeyAndOrderFront(nil)
        
        // Bring app to foreground
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - 5. Entry Point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()