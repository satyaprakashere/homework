#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>


// --- SHADER SOURCE ---
// Intel Macs prefer explicit attribute locations
static NSString *const kShaderSource =
@"#include <metal_stdlib>\n"
"   using namespace metal;\n"
"   struct VertexIn {\n"
"       float3 position [[attribute(0)]];\n"
"   };\n"
"   vertex float4 vertex_main(VertexIn in [[stage_in]]) {\n"
"       return float4(in.position, 1.0);\n"
"}  \n"
"   fragment float4 fragment_main() {\n"
"       return float4(1.0, 0.0, 0.5, 1.0); // Pink/Magenta\n"
"   }\n";

@interface TriangleView : MTKView <MTKViewDelegate>
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@end

@implementation TriangleView

- (instancetype)initWithFrame:(NSRect)frame device:(id<MTLDevice>)device {
    self = [super initWithFrame:frame device:device];
    if (self) {
        self.delegate = self;
        [self setupMetal];
    }
    return self;
}

- (void)setupMetal {
    self.commandQueue = [self.device newCommandQueue];
    NSError *error = nil;
    
    // Compile Shader
    id<MTLLibrary> library = [self.device newLibraryWithSource:kShaderSource options:nil error:&error];
    if (!library) { NSLog(@"Shader Error: %@", error); return; }

    // Define Vertex Layout (Crucial for Intel compatibility)
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.layouts[0].stride = sizeof(float) * 3;

    // Create Pipeline State
    MTLRenderPipelineDescriptor *pd = [[MTLRenderPipelineDescriptor alloc] init];
    pd.vertexFunction = [library newFunctionWithName:@"vertex_main"];
    pd.fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    pd.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    pd.vertexDescriptor = vertexDescriptor;
    
    self.pipelineState = [self.device newRenderPipelineStateWithDescriptor:pd error:&error];
    if (!self.pipelineState) { NSLog(@"Pipeline Error: %@", error); }
}

- (void)drawInMTKView:(MTKView *)view {
    static const float vertices[] = { 0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0 };
    
    id<MTLCommandBuffer> buffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    
    if (pass) {
        id<MTLRenderCommandEncoder> enc = [buffer renderCommandEncoderWithDescriptor:pass];
        [enc setRenderPipelineState:self.pipelineState];
        [enc setVertexBytes:vertices length:sizeof(vertices) atIndex:0];
        [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [enc endEncoding];
        [buffer presentDrawable:view.currentDrawable];
    }
    [buffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}
@end

// --- APP DELEGATE TO STOP HANGING ---
@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (strong) NSWindow *window;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSRect frame = NSMakeRect(0, 0, 800, 600);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                             styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
                                               backing:NSBackingStoreBuffered defer:NO];
    [self.window setTitle:@"Metal x86 Triangle"];
    
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    TriangleView *view = [[TriangleView alloc] initWithFrame:frame device:device];
    [self.window setContentView:view];
    [self.window makeKeyAndOrderFront:nil];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }
@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
    return 0;
}