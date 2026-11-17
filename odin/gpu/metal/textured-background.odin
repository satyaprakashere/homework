package metal_appkit

import "core:fmt"
import "core:sys/darwin/Foundation"
import "vendor:darwin/Metal"
import "vendor:darwin/QuartzCore"

main :: proc() {
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
	window->setTitle(Foundation.MakeConstantString("Apple Linen Textured Background"))
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
	if pipeline_state == nil {
		fmt.panicf("Pipeline error: %s", perr->localizedDescription())
	}
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
		// Draw fullscreen textured background (triangle covering the viewport)
		encoder->drawPrimitives(.Triangle, 0, 3)
		encoder->endEncoding()

		buffer->presentDrawable(drawable)
		buffer->commit()
	}
}

SHADER_SOURCE := `
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
	float4 position [[position]];
	float2 uv;
};

// Fullscreen triangle covering the entire viewport [-1, 1]
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0),
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = positions[vertexID] * 0.5 + 0.5;
    return out;
}

// Pseudo-random hash for grain and natural linen slub irregularities
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123);
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    float2 pos = in.position.xy;

    // --- 1. Authentic Apple Linen Weave ---
    // Thread pitch in pixels
    float threadPitch = 4.0;
    float2 grid = pos / threadPitch;
    float2 cell = floor(grid);
    float2 f = fract(grid);

    // Checkerboard weave determines whether vertical or horizontal yarn is on top
    bool isVertical = ((int(cell.x) + int(cell.y)) % 2) == 0;

    // u: cross-section profile, v: along thread direction
    float u = isVertical ? f.x : f.y;
    float v = isVertical ? f.y : f.x;

    // Rounded cylindrical curve of the yarn
    float threadProfile = sin(u * 3.14159265);

    // Yarn dips under adjacent thread at boundaries
    float tuck = sin(v * 3.14159265);
	float tuckFactor = mix(0.62, 1.0, tuck);

    // Longitudinal micro-fiber striations
    float striation = 0.5 + 0.5 * sin(u * 6.2831853 * 2.0);

    // Natural slub variations (linen organic texture)
    float slub = hash(cell) * 0.16 - 0.08;

    // Composite weave intensity
    float weave = (threadProfile * 0.72 + striation * 0.28) * tuckFactor + slub;

    // Ambient occlusion crevices between threads
    float seamX = smoothstep(0.0, 0.14, f.x) * smoothstep(1.0, 0.86, f.x);
    float seamY = smoothstep(0.0, 0.14, f.y) * smoothstep(1.0, 0.86, f.y);
    float seam = seamX * seamY;
    weave *= mix(0.55, 1.0, seam);

    // --- 2. High-Frequency Tactile Cloth Grain ---
    float grain = (hash(pos) - 0.5) * 0.065;

    // --- 3. Apple Linen Palette & Color Grading ---
    // Classic slate charcoal tones
    float3 shadowColor = float3(0.095, 0.102, 0.115);
    float3 midColor    = float3(0.180, 0.192, 0.212);
    float3 crownColor  = float3(0.255, 0.272, 0.300);

    float3 color;
    if (weave < 0.5) {
        color = mix(shadowColor, midColor, weave * 2.0);
    } else {
        color = mix(midColor, crownColor, (weave - 0.5) * 2.0);
    }
    color += float3(grain);

    // --- 4. Soft Apple Overhead Lighting & Radial Vignette ---
    // Subtle top-down illumination
    float topLight = mix(0.93, 1.06, in.uv.y);

    // Gentle radial vignette falloff
    float2 dist = (in.uv - 0.5) * 1.35;
    float vignette = clamp(1.0 - dot(dist, dist) * 0.32, 0.76, 1.0);

    color *= topLight * vignette;

    return float4(clamp(color, 0.0, 1.0), 1.0);
}
`
