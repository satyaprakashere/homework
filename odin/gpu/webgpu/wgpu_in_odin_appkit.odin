package wgpu_appkit

import "core:fmt"

import NS "vendor:darwin/AppKit"
import CA "vendor:darwin/QuartzCore"
import "vendor:wgpu"

import "base:runtime"
import "core:time"

OS :: struct {
	app:         ^NS.Application,
	window:      ^NS.Window,
	metal_layer: ^CA.MetalLayer,
}

State :: struct {
	ctx:             runtime.Context,
	os:              OS,
	instance:        wgpu.Instance,
	surface:         wgpu.Surface,
	adapter:         wgpu.Adapter,
	device:          wgpu.Device,
	config:          wgpu.SurfaceConfiguration,
	queue:           wgpu.Queue,
	module:          wgpu.ShaderModule,
	pipeline_layout: wgpu.PipelineLayout,
	pipeline:        wgpu.RenderPipeline,
	running:         bool,
}

@(private = "file")
state: State

main :: proc() {
	state.ctx = context

	os_init(&state.os)

	state.instance = wgpu.CreateInstance(nil)
	if state.instance == nil {
		panic("WebGPU is not supported")
	}
	state.surface = os_get_surface(&state.os, state.instance)

	// Requests should be message to Devatas
	wgpu.InstanceRequestAdapter(
		state.instance,
		&{compatibleSurface = state.surface},
		{callback = on_adapter},
	)
}

resize :: proc "c" () {
	context = state.ctx

	state.config.width, state.config.height = os_get_render_bounds(&state.os)
	wgpu.SurfaceConfigure(state.surface, &state.config)
}

frame :: proc "c" (dt: f32) {
	context = state.ctx

	surface_texture := wgpu.SurfaceGetCurrentTexture(state.surface)
	#partial switch surface_texture.status {
	case .SuccessOptimal, .SuccessSuboptimal:
	// All good, could handle suboptimal here.
	case .Timeout, .Outdated, .Lost:
		// Skip this frame, and re-configure surface.
		if surface_texture.texture != nil {
			wgpu.TextureRelease(surface_texture.texture)
		}
		resize()
		return
//		case .OutOfMemory, .DeviceLost, .Error:
//		// Fatal error
//		fmt.panicf("[triangle] get_current_texture status=%v", surface_texture.status)
	}
	defer wgpu.TextureRelease(surface_texture.texture)

	frame := wgpu.TextureCreateView(surface_texture.texture, nil)
	defer wgpu.TextureViewRelease(frame)

	command_encoder := wgpu.DeviceCreateCommandEncoder(state.device, nil)
	defer wgpu.CommandEncoderRelease(command_encoder)

	render_pass_encoder := wgpu.CommandEncoderBeginRenderPass(
		command_encoder,
		&{
			colorAttachmentCount = 1,
			colorAttachments = &wgpu.RenderPassColorAttachment {
				view = frame,
				loadOp = .Clear,
				storeOp = .Store,
				depthSlice = wgpu.DEPTH_SLICE_UNDEFINED,
				clearValue = {0, 1, 0, 1},
			},
		},
	)

	wgpu.RenderPassEncoderSetPipeline(render_pass_encoder, state.pipeline)
	wgpu.RenderPassEncoderDraw(
		render_pass_encoder,
		vertexCount = 3,
		instanceCount = 1,
		firstVertex = 0,
		firstInstance = 0,
	)

	wgpu.RenderPassEncoderEnd(render_pass_encoder)
	wgpu.RenderPassEncoderRelease(render_pass_encoder)

	command_buffer := wgpu.CommandEncoderFinish(command_encoder, nil)
	defer wgpu.CommandBufferRelease(command_buffer)

	wgpu.QueueSubmit(state.queue, {command_buffer})
	wgpu.SurfacePresent(state.surface)
}

finish :: proc() {
	wgpu.RenderPipelineRelease(state.pipeline)
	wgpu.PipelineLayoutRelease(state.pipeline_layout)
	wgpu.ShaderModuleRelease(state.module)
	wgpu.QueueRelease(state.queue)
	wgpu.DeviceRelease(state.device)
	wgpu.AdapterRelease(state.adapter)
	wgpu.SurfaceRelease(state.surface)
	wgpu.InstanceRelease(state.instance)
}


os_init :: proc(os: ^OS) {
	os.app = NS.Application_sharedApplication()
	os.app->setActivationPolicy(.Regular)
	os.app->activateIgnoringOtherApps(true)

	rect := NS.Rect{{0, 0}, {960, 540}}
	os.window = NS.Window.alloc()->initWithContentRect(
		rect,
		{.Titled, .Closable, .Resizable},
		.Buffered,
		false,
	)
	os.window->setTitle(NS.MakeConstantString("WGPU Native Triangle"))
	os.window->center()
	os.window->makeKeyAndOrderFront(nil)

	os.metal_layer = CA.MetalLayer.layer()
	os.metal_layer->setPixelFormat(.BGRA8Unorm)

	view := os.window->contentView()
	view->setLayer(os.metal_layer)
	view->setWantsLayer(true)

	window_delegate := NS.window_delegate_register_and_alloc({
			windowWillClose = proc(notification: ^NS.Notification) {
				state.running = false
			},
			windowDidResize = proc(notification: ^NS.Notification) {
				resize()
			},
		}, "WindowDelegate", context)
	os.window->setDelegate(window_delegate)

	state.running = true
}

os_run :: proc(os: ^OS) {
	last := time.tick_now()
	main_loop: for state.running {
		for {
			event := os.app->nextEventMatchingMask(
				NS.EventMaskAny,
				NS.Date.distantPast(),
				NS.DefaultRunLoopMode,
				true,
			)
			if event == nil do break
			os.app->sendEvent(event)
		}

		now := time.tick_now()
		dt := f32(time.duration_seconds(time.tick_diff(last, now)))
		last = now

		frame(dt)
	}

	finish()
}


os_get_render_bounds :: proc(os: ^OS) -> (width, height: u32) {
	view := os.window->contentView()
	rect := os.window->convertRectToBacking(view->bounds())
	return u32(rect.size.width), u32(rect.size.height)
}

os_get_surface :: proc(os: ^OS, instance: wgpu.Instance) -> wgpu.Surface {
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor {
			nextInChain = &wgpu.SurfaceSourceMetalLayer {
				chain = {sType = .SurfaceSourceMetalLayer},
				layer = rawptr(os.metal_layer),
			},
		},
	)
}

on_adapter :: proc "c" (
	status: wgpu.RequestAdapterStatus,
	adapter: wgpu.Adapter,
	message: string,
	userdata1, userdata2: rawptr,
) {
	context = state.ctx
	if status != .Success || adapter == nil {
		fmt.panicf("request adapter failure: [%v] %s", status, message)
	}
	state.adapter = adapter
	wgpu.AdapterRequestDevice(adapter, nil, {callback = on_device})
}

on_device :: proc "c" (
	status: wgpu.RequestDeviceStatus,
	device: wgpu.Device,
	message: string,
	userdata1, userdata2: rawptr,
) {
	context = state.ctx
	if status != .Success || device == nil {
		fmt.panicf("request device failure: [%v] %s", status, message)
	}
	state.device = device
	
	width, height := os_get_render_bounds(&state.os)
	
	state.config = wgpu.SurfaceConfiguration {
		device      = state.device,
		usage       = {.RenderAttachment},
		format      = .BGRA8Unorm,
		width       = width,
		height      = height,
		presentMode = .Fifo,
		alphaMode   = .Opaque,
	}
	wgpu.SurfaceConfigure(state.surface, &state.config)
	
	state.queue = wgpu.DeviceGetQueue(state.device)
	
	shader :: `
		@vertex
		fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
			let x = f32(i32(in_vertex_index) - 1);
			let y = f32(i32(in_vertex_index & 1u) * 2 - 1);
			return vec4<f32>(x, y, 0.0, 1.0);
		}
		
		@fragment
		fn fs_main() -> @location(0) vec4<f32> {
			return vec4<f32>(1.0, 0.0, 0.0, 1.0);
		}`
	
	state.module = wgpu.DeviceCreateShaderModule(
		state.device,
		&{nextInChain = &wgpu.ShaderSourceWGSL{sType = .ShaderSourceWGSL, code = shader}},
	)
	
	state.pipeline_layout = wgpu.DeviceCreatePipelineLayout(state.device, &{})
	state.pipeline = wgpu.DeviceCreateRenderPipeline(
		state.device,
		&{
			layout = state.pipeline_layout,
			vertex = {module = state.module, entryPoint = "vs_main"},
			fragment = &{
				module = state.module,
				entryPoint = "fs_main",
				targetCount = 1,
				targets = &wgpu.ColorTargetState {
					format = .BGRA8Unorm,
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			},
			primitive = {topology = .TriangleList},
			multisample = {count = 1, mask = 0xFFFFFFFF},
		},
	)
	
	os_run(&state.os)
}
