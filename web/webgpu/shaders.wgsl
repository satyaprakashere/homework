struct VertexOut {
    @builtin(position) position: vec4f,
    @location(0) color: vec4f,
}

@vertex
fn vs_main(@builtin(vertex_index) vertexIndex: u32) -> VertexOut {
    var pos = array<vec2f, 3>(
        vec2f(0.0, 0.5),  // Top
        vec2f(-0.5, -0.5),  // Bottom Left
        vec2f(0.5, -0.5)   // Bottom Right
    );

    var color = array<vec4f, 3>(
        vec4f(1.0, 0.0, 0.0, 1.0),  // Red
        vec4f(0.0, 1.0, 0.0, 1.0),  // Green
        vec4f(0.0, 0.0, 1.0, 1.0)   // Blue
    );

    var output: VertexOut;
    output.position = vec4f(pos[vertexIndex], 0.0, 1.0);
    output.color = color[vertexIndex];

    return output;
}

@fragment
fn fs_main(@location(0) color: vec4f) -> @location(0) vec4f {
    return color;
}