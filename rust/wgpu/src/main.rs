use std::sync::Arc;
use winit::{
    event::{Event, WindowEvent},
    event_loop::EventLoop,
    window::WindowBuilder,
};

async fn run() {
    let event_loop = EventLoop::new().unwrap();
    let window = Arc::new(WindowBuilder::new()
        .with_title("wgpu Hello Triangle")
        .build(&event_loop)
        .unwrap());

    let size = window.inner_size();

    // 1. Core WebGPU Instance setup
    let instance = wgpu::Instance::default();
    
    // 2. Creating the window surface context
    let surface = instance.create_surface(window.clone()).unwrap();
    
    // 3. Picking the physical hardware Adapter
    let adapter = instance
        .request_adapter(&wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::HighPerformance,
            compatible_surface: Some(&surface),
            force_fallback_adapter: false,
        })
        .await
        .expect("Failed to find an appropriate graphics adapter.");

    // 4. Activating the logical Device and its Command Queue
    let (device, queue) = adapter
        .request_device(
            &wgpu::DeviceDescriptor {
                label: None,
                required_features: wgpu::Features::empty(),
                required_limits: wgpu::Limits::default(),
            },
            None,
        )
        .await
        .expect("Failed to create device.");

    // 5. Configuring how the surface renders to the window dimensions
    let surface_caps = surface.get_capabilities(&adapter);
    let surface_format = surface_caps.formats[0];
    let mut config = wgpu::SurfaceConfiguration {
        usage: wgpu::TextureUsages::RENDER_ATTACHMENT,
        format: surface_format,
        width: size.width,
        height: size.height,
        present_mode: wgpu::PresentMode::Fifo,
        alpha_mode: surface_caps.alpha_modes[0],
        view_formats: vec![],
        desired_maximum_frame_latency: 2,
    };
    surface.configure(&device, &config);

    // 6. Loading the WGSL Shader module
    let shader = device.create_shader_module(wgpu::include_wgsl!("../shader.wgsl"));

    // 7. Creating the explicit pipeline layout
    let render_pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Render Pipeline Layout"),
        bind_group_layouts: &[],
        push_constant_ranges: &[],
    });

    // 8. Defining the Immutable Pipeline State Object (PSO)
    let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: Some("Render Pipeline"),
        layout: Some(&render_pipeline_layout),
        vertex: wgpu::VertexState {
            module: &shader,
            entry_point: Some("vs_main"),
            buffers: &[], // No vertex buffers passed; using hardcoded indexing in shader
        },
        fragment: Some(wgpu::FragmentState {
            module: &shader,
            entry_point: Some("fs_main"),
            targets: &[Some(wgpu::ColorTargetState {
                format: config.format,
                blend: Some(wgpu::BlendState::REPLACE),
                write_mask: wgpu::ColorWrites::ALL,
            })],
        }),
        primitive: wgpu::PrimitiveState {
            topology: wgpu::PrimitiveTopology::TriangleList,
            ..Default::default()
        },
        depth_stencil: None,
        multisample: wgpu::MultisampleState::default(),
        multiview: None,
        cache: None,
    });

    // 9. Running the active event loop
    let _ = event_loop.run(move |event, elwt| match event {
        Event::WindowEvent { event: WindowEvent::CloseRequested, .. } => elwt.exit(),
        Event::WindowEvent { event: WindowEvent::Resized(new_size), .. } => {
            if new_size.width > 0 && new_size.height > 0 {
                config.width = new_size.width;
                config.height = new_size.height;
                surface.configure(&device, &config);
                window.request_redraw();
            }
        }
        Event::AboutToWait => {
            window.request_redraw();
        }
        Event::WindowEvent { event: WindowEvent::RedrawRequested, .. } => {
            // Grab a blank texture frame from the surface
            let frame = surface.get_current_texture().expect("Failed to acquire next swap chain texture");
            let view = frame.texture.create_view(&wgpu::TextureViewDescriptor::default());
            
            // Build a command encoder to batch graphics commands
            let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
                label: Some("Render Encoder"),
            });

            {
                // Instantiate our drawing render pass
                let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
                    label: Some("Render Pass"),
                    color_attachments: &[Some(wgpu::RenderPassColorAttachment {
                        view: &view,
                        resolve_target: None,
                        ops: wgpu::Operations {
                            load: wgpu::LoadOp::Clear(wgpu::Color { r: 0.1, g: 0.2, b: 0.3, a: 1.0 }), // Dark blue bg
                            store: wgpu::StoreOp::Store,
                        },
                    })],
                    depth_stencil_attachment: None,
                    timestamp_writes: None,
                    occlusion_query_set: None,
                });

                // Bind our pipeline and draw 3 vertices (1 triangle)
                render_pass.set_pipeline(&render_pipeline);
                render_pass.draw(0..3, 0..1);
            }

            // Submit the finalized buffer command to the hardware queue
            queue.submit(std::iter::once(encoder.finish()));
            frame.present();
        }
        _ => {}
    });
}

fn main() {
    // Since wgpu initialization calls are async, block execution until setup completes
    pollster::block_on(run());
}