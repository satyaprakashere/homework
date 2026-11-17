package metal_appkit

import "core:fmt"
import "core:sys/darwin/Foundation"
import "vendor:darwin/Metal"
import "vendor:darwin/QuartzCore"

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

main :: proc() {
	// Explicitly reference namespaces instead of 'using'
	app := Foundation.Application_sharedApplication()
	app->setActivationPolicy(.Regular)
	app->activateIgnoringOtherApps(true)

	rect := Foundation.Rect{{0, 0}, {800, 600}}
	window := Foundation.Window_alloc()->initWithContentRect(
		rect,
		{.Titled, .Closable, .Resizable},
		.Buffered,
		false,
	)
	window->setTitle(Foundation.MakeConstantString("Odin Metal Triangle"))
	window->makeKeyAndOrderFront(nil)

	device := Metal.CreateSystemDefaultDevice()

	// Setup Metal Layer
	metal_layer := QuartzCore.MetalLayer_layer()
	metal_layer->setDevice(device)
	metal_layer->setPixelFormat(.BGRA8Unorm)

	view := window->contentView()
	view->setLayer(metal_layer)
	view->setWantsLayer(true)


	// Library & Pipeline Setup
	//	err: ^Foundation.Error
	source_str := Foundation.String_initWithOdinString(Foundation.String_alloc(), SHADER_SOURCE)
	library, err := device->newLibraryWithSource(source_str, nil)
	if library == nil {
		fmt.panicf("Shader error: %s", err->localizedDescription())
	}

	v_func := library->newFunctionWithName(Foundation.MakeConstantString("vertex_main"))
	f_func := library->newFunctionWithName(Foundation.MakeConstantString("fragment_main"))

	psd := Metal.RenderPipelineDescriptor_alloc()->init()
	psd->setVertexFunction(v_func)
	psd->setFragmentFunction(f_func)
	psd->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm)

	pipeline_state, perr := device->newRenderPipelineStateWithDescriptor(psd)
	queue := device->newCommandQueue()

	// Main Loop
	for Foundation.Window_isResizable(window) {
		for {
			event := app->nextEventMatchingMask(
				Foundation.EventMaskAny,
				Foundation.Date_distantPast(),
				Foundation.DefaultRunLoopMode,
				true,
			)
			if event == nil do break
			app->sendEvent(event)
		}

		drawable := metal_layer->nextDrawable()
		if drawable == nil do continue

		pass := Metal.RenderPassDescriptor_renderPassDescriptor()
		ca := pass->colorAttachments()->object(0)
		ca->setClearColor(Metal.ClearColor{0.1, 0.1, 0.1, 1.0})
		ca->setLoadAction(.Clear)
		ca->setTexture(drawable->texture())

		buffer := queue->commandBuffer()
		encoder := buffer->renderCommandEncoderWithDescriptor(pass)
		encoder->setRenderPipelineState(pipeline_state)
		encoder->drawPrimitives(.Triangle, 0, 3)
		encoder->endEncoding()

		buffer->presentDrawable(drawable)
		buffer->commit()
	}
}
