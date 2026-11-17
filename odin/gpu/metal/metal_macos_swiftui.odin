package main

import "core:fmt"
import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import MTK "vendor:darwin/MetalKit"

SHADER_SOURCE := `
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[3] = { float2(0.0, 0.5), float2(-0.5, -0.5), float2(0.5, -0.5) };
    float4 colors[3]    = { float4(1, 0, 0, 1), float4(0, 1, 0, 1), float4(0, 0, 1, 1) };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.color = colors[vertexID];
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
`

// AppState holds all Metal resources shared across delegate callbacks.
AppState :: struct {
	device:         ^MTL.Device,
	pipeline_state: ^MTL.RenderPipelineState,
	command_queue:  ^MTL.CommandQueue,
}

g_app_state: AppState

// MTKViewDelegate: called once per frame by the MTKView display link.
draw_in_mtk_view :: proc "c" (delegate: ^MTK.ViewDelegate, view: ^MTK.View) {
	state := cast(^AppState)delegate.user_data

	drawable := view->currentDrawable()
	if drawable == nil do return

	pass := view->currentRenderPassDescriptor()
	if pass == nil do return

	ca := pass->colorAttachments()->object(0)
	ca->setClearColor(MTL.ClearColor{0.1, 0.1, 0.1, 1.0})
	ca->setLoadAction(.Clear)
	ca->setStoreAction(.Store)

	buffer := state.command_queue->commandBuffer()
	encoder := buffer->renderCommandEncoderWithDescriptor(pass)
	encoder->setRenderPipelineState(state.pipeline_state)
	encoder->drawPrimitives(.Triangle, 0, 3)
	encoder->endEncoding()

	buffer->presentDrawable(drawable)
	buffer->commit()
}

// MTKViewDelegate: called when the drawable size changes (e.g. window resize).
drawable_size_will_change :: proc "c" (
	delegate: ^MTK.ViewDelegate,
	view: ^MTK.View,
	size: NS.Size,
) {
	// Nothing to update for this simple triangle demo.
}

// NSApplicationDelegate: called after the app finishes launching.
// This is the SwiftUI-style entry point — set up your window and views here.
app_did_finish_launching :: proc(notification: ^NS.Notification) {
	state := &g_app_state
	state.device = MTL.CreateSystemDefaultDevice()

	// Build the shader library and pipeline
	source_str := NS.String.initWithOdinString(NS.String.alloc(), SHADER_SOURCE)
	library, err := state.device->newLibraryWithSource(source_str, nil)
	if library == nil {
		fmt.panicf("Shader error: %s", err->localizedDescription())
	}

	v_func := library->newFunctionWithName(NS.MakeConstantString("vertex_main"))
	f_func := library->newFunctionWithName(NS.MakeConstantString("fragment_main"))

	psd := MTL.RenderPipelineDescriptor.alloc()->init()
	psd->setVertexFunction(v_func)
	psd->setFragmentFunction(f_func)
	psd->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm)

	pipeline_state, perr := state.device->newRenderPipelineStateWithDescriptor(psd)
	if pipeline_state == nil {
		fmt.panicf("Pipeline error: %s", perr->localizedDescription())
	}
	state.pipeline_state = pipeline_state
	state.command_queue = state.device->newCommandQueue()

	// Create the MTKView (replaces manual CAMetalLayer + NSView wiring)
	rect := NS.Rect{{0, 0}, {800, 600}}
	mtk_view := MTK.View.alloc()->initWithFrame(rect, state.device)
	mtk_view->setColorPixelFormat(.BGRA8Unorm)
	mtk_view->setClearColor(MTL.ClearColor{0.1, 0.1, 0.1, 1.0})
	mtk_view->setPreferredFramesPerSecond(60)

	// Attach the render delegate
	view_delegate := new(MTK.ViewDelegate)
	view_delegate^ = {
		drawInMTKView          = draw_in_mtk_view,
		drawableSizeWillChange = drawable_size_will_change,
		user_data              = state,
	}
	mtk_view->setDelegate(view_delegate)

	// Create the window and set the MTKView as its content view
	window := NS.Window.alloc()->initWithContentRect(
		rect,
		{.Titled, .Closable, .Resizable},
		.Buffered,
		false,
	)
	window->setTitle(NS.MakeConstantString("Odin Metal Triangle (SwiftUI-style)"))
	window->setContentView(mtk_view)
	window->makeKeyAndOrderFront(nil)
	window->center()
}

app_should_terminate_after_last_window_closed :: proc(sender: ^NS.Application) -> NS.BOOL {
	return true
}

main :: proc() {
	app := NS.Application.sharedApplication()
	app->setActivationPolicy(.Regular)
	app->activateIgnoringOtherApps(true)

	// Register an NSApplicationDelegate — the SwiftUI-equivalent lifecycle hook.
	delegate := NS.application_delegate_register_and_alloc(
		{
			applicationDidFinishLaunching = app_did_finish_launching,
			applicationShouldTerminateAfterLastWindowClosed = app_should_terminate_after_last_window_closed,
		},
		"AppDelegate",
		nil,
	)
	app->setDelegate(delegate)

	// Hand control to the Cocoa run loop.
	// MTKView drives rendering via its internal CVDisplayLink — no manual loop needed.
	app->run()
}
