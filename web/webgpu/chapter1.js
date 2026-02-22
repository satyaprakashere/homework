async function init() {
  if (!navigator.gpu) throw new Error("WebGPU not supported");

  const adapter = await navigator.gpu.requestAdapter();
  const device = await adapter.requestDevice();
  const canvas = document.getElementById("gpuCanvas");
  const context = canvas.getContext("webgpu");
  const presentationFormat = navigator.gpu.getPreferredCanvasFormat();

  context.configure({
    device,
    format: presentationFormat,
    alphaMode: "premultiplied",
  });

  // --- STEP 1: Create Devanagari Texture via 2D Canvas ---
  const text = "नमस्ते वेबGPU"; // "Namaste WebGPU"
  const fontSize = 48;
  const font = "bold " + fontSize + "px 'Noto Sans Devanagari', sans-serif";

  // Measure text to size the texture efficiently
  const measureCtx = document.createElement("canvas").getContext("2d");
  measureCtx.font = font;
  const textMetrics = measureCtx.measureText(text);
  const width = Math.ceil(textMetrics.width);
  const height = Math.ceil(fontSize * 1.5); // Add buffer for ascenders/descenders

  // Create the actual source canvas
  const textCanvas = new OffscreenCanvas(width, height);
  const ctx = textCanvas.getContext("2d");
  ctx.fillStyle = "white"; // Text color
  ctx.font = font;
  ctx.textBaseline = "middle";
  ctx.fillText(text, 0, height / 2);

  // Create WebGPU Texture
  const texture = device.createTexture({
    size: [width, height, 1],
    format: "rgba8unorm",
    usage:
      GPUTextureUsage.TEXTURE_BINDING |
      GPUTextureUsage.COPY_DST |
      GPUTextureUsage.RENDER_ATTACHMENT,
  });

  // Copy 2D Canvas data to WebGPU Texture
  device.queue.copyExternalImageToTexture(
    { source: textCanvas, flipY: true }, // Flip Y if your UVs expect it
    { texture: texture },
    [width, height]
  );

  // --- STEP 2: Standard WebGPU Quad Rendering ---
  // (Simplified for brevity: Boilerplate pipeline setup)
  
  // Shaders
  const shaderModule = device.createShaderModule({
    code: `
      struct VertexOutput {
        @builtin(position) Position : vec4f,
        @location(0) uv : vec2f,
      }

      @vertex
      fn vs_main(@builtin(vertex_index) VertexIndex : u32) -> VertexOutput {
        // Hardcoded full-screen quad (for demo simplicity)
        var pos = array<vec2f, 6>(
          vec2f(-0.8, -0.8), vec2f(0.8, -0.8), vec2f(-0.8, 0.8),
          vec2f(-0.8, 0.8), vec2f(0.8, -0.8), vec2f(0.8, 0.8)
        );
        var uv = array<vec2f, 6>(
          vec2f(0.0, 1.0), vec2f(1.0, 1.0), vec2f(0.0, 0.0),
          vec2f(0.0, 0.0), vec2f(1.0, 1.0), vec2f(1.0, 0.0)
        );

        var output : VertexOutput;
        output.Position = vec4f(pos[VertexIndex], 0.0, 1.0);
        output.uv = uv[VertexIndex];
        return output;
      }

      @group(0) @binding(0) var mySampler : sampler;
      @group(0) @binding(1) var myTexture : texture_2d<f32>;

      @fragment
      fn fs_main(@location(0) uv : vec2f) -> vec4f {
        return textureSample(myTexture, mySampler, uv);
      }
    `
  });

  const pipeline = device.createRenderPipeline({
    layout: "auto",
    vertex: { module: shaderModule, entryPoint: "vs_main" },
    fragment: {
      module: shaderModule,
      entryPoint: "fs_main",
      targets: [{ 
        format: presentationFormat,
        blend: { // Important for transparent text backgrounds
            color: { srcFactor: 'src-alpha', dstFactor: 'one-minus-src-alpha', operation: 'add'},
            alpha: { srcFactor: 'one', dstFactor: 'one-minus-src-alpha', operation: 'add'},
        }
      }],
    },
    primitive: { topology: "triangle-list" },
  });

  const sampler = device.createSampler({
    magFilter: "linear",
    minFilter: "linear",
  });

  const bindGroup = device.createBindGroup({
    layout: pipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: sampler },
      { binding: 1, resource: texture.createView() },
    ],
  });

  // Render Loop
  function frame() {
    const commandEncoder = device.createCommandEncoder();
    const textureView = context.getCurrentTexture().createView();

    const passEncoder = commandEncoder.beginRenderPass({
      colorAttachments: [{
        view: textureView,
        clearValue: { r: 0.1, g: 0.1, b: 0.1, a: 1.0 },
        loadOp: "clear",
        storeOp: "store",
      }],
    });

    passEncoder.setPipeline(pipeline);
    passEncoder.setBindGroup(0, bindGroup);
    passEncoder.draw(6);
    passEncoder.end();

    device.queue.submit([commandEncoder.finish()]);
    requestAnimationFrame(frame);
  }

  requestAnimationFrame(frame);
}

init();