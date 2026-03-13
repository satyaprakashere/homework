package main

import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import SDL "vendor:sdl3"

import "core:fmt"
import "core:os"

main :: proc() {
	err := metal_sdl3_main()
	if err == nil {
		return
	}

	fmt.eprintln(err->localizedDescription()->odinString())
	os.exit(1)
}

metal_sdl3_main :: proc() -> (err: ^NS.Error) {
	SDL.SetHint(SDL.HINT_RENDER_DRIVER, "metal")
	_ = SDL.SetAppMetadataProperty(SDL.PROP_APP_METADATA_NAME_STRING, "Metal in Odin")

	if !SDL.Init({.VIDEO}) {
		fmt.eprintln("SDL Init failed")
		os.exit(1)
	}
	defer SDL.Quit()

	window := SDL.CreateWindow(
		"Metal in Odin",
		854,
		480,
		{.HIGH_PIXEL_DENSITY, .HIDDEN, .RESIZABLE},
	)
	if window == nil {
		fmt.eprintln("SDL CreateWindow failed")
		os.exit(1)
	}
	defer SDL.DestroyWindow(window)

	device := MTL.CreateSystemDefaultDevice()
	fmt.println(device->name()->odinString())

	// Create SDL Metal View
	view := SDL.Metal_CreateView(window)
	if view == nil {
		fmt.eprintln("SDL Metal_CreateView failed")
		os.exit(1)
	}
	defer SDL.Metal_DestroyView(view)

	// Get the CAMetalLayer from the view
	layer_handle := SDL.Metal_GetLayer(view)
	swapchain := (^CA.MetalLayer)(layer_handle)

	swapchain->setDevice(device)
	swapchain->setPixelFormat(.BGRA8Unorm_sRGB)
	swapchain->setFramebufferOnly(true)
	// No need to set frame manually, SDL handles the view

	command_queue := device->newCommandQueue()

	compile_options := NS.new(MTL.CompileOptions)
	defer compile_options->release()


	program_source :: `
	using namespace metal;

	struct ColoredVertex {
		float4 position [[position]];
		float4 color;
	};

	vertex ColoredVertex vertex_main(constant float4 *position [[buffer(0)]],
	                                 constant float4 *color    [[buffer(1)]],
	                                 uint vid                  [[vertex_id]]) {
		ColoredVertex vert;
		vert.position = position[vid];
		vert.color    = color[vid];
		return vert;
	}

	fragment float4 fragment_main(ColoredVertex vert [[stage_in]]) {
		return vert.color;
	}
	`
	program_library := device->newLibraryWithSource(
		NS.AT(program_source),
		compile_options,
	) or_return

	vertex_program := program_library->newFunctionWithName(NS.AT("vertex_main"))
	fragment_program := program_library->newFunctionWithName(NS.AT("fragment_main"))
	assert(vertex_program != nil)
	assert(fragment_program != nil)


	pipeline_state_descriptor := NS.new(MTL.RenderPipelineDescriptor)
	pipeline_state_descriptor->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm_sRGB)
	pipeline_state_descriptor->setVertexFunction(vertex_program)
	pipeline_state_descriptor->setFragmentFunction(fragment_program)

	pipeline_state := device->newRenderPipelineState(pipeline_state_descriptor) or_return

	positions := [?][4]f32{{0.0, 0.5, 0, 1}, {-0.5, -0.5, 0, 1}, {0.5, -0.5, 0, 1}}
	colors := [?][4]f32{{1, 0, 0, 1}, {0, 1, 0, 1}, {0, 0, 1, 1}}

	position_buffer := device->newBufferWithSlice(positions[:], {})
	color_buffer := device->newBufferWithSlice(colors[:], {})


	SDL.ShowWindow(window)

	quit := false
	for !quit {
		e: SDL.Event
		for SDL.PollEvent(&e) {
			if e.type == .QUIT {
				quit = true
			}
			if e.type == .KEY_DOWN {
				if e.key.key == SDL.K_ESCAPE {
					quit = true
				}
			}
		}

		NS.scoped_autoreleasepool()

		drawable := swapchain->nextDrawable()
		// In some cases nextDrawable can return nil (e.g. if window is minimized or not ready)
		if drawable == nil {
			continue
		}

		pass := MTL.RenderPassDescriptor.renderPassDescriptor()
		color_attachment := pass->colorAttachments()->object(0)
		assert(color_attachment != nil)
		color_attachment->setClearColor(MTL.ClearColor{0.25, 0.5, 1.0, 1.0})
		color_attachment->setLoadAction(.Clear)
		color_attachment->setStoreAction(.Store)
		color_attachment->setTexture(drawable->texture())


		command_buffer := command_queue->commandBuffer()
		render_encoder := command_buffer->renderCommandEncoderWithDescriptor(pass)

		render_encoder->setRenderPipelineState(pipeline_state)
		render_encoder->setVertexBuffer(position_buffer, 0, 0)
		render_encoder->setVertexBuffer(color_buffer, 0, 1)
		render_encoder->drawPrimitivesWithInstanceCount(.Triangle, 0, 3, 1)

		render_encoder->endEncoding()

		command_buffer->presentDrawable(drawable)
		command_buffer->commit()
	}

	return nil
}
