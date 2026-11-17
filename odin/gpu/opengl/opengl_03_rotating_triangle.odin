package main

import "core:fmt"
import "core:math"
import gl "vendor:OpenGL"
import "vendor:glfw"

/*
    OPENGL_03: ROTATING TRIANGLE (UNIFORMS)
    
    Shows how to pass data from the CPU to the GPU using uniforms.
    We'll use a transformation matrix to rotate the triangle.
*/

VERTEX_SHADER_SOURCE := `
#version 330 core
layout (location = 0) in vec3 aPos;
uniform mat4 transform;
void main() {
    gl_Position = transform * vec4(aPos, 1.0);
}
`

FRAGMENT_SHADER_SOURCE := `
#version 330 core
out vec4 FragColor;
void main() {
    FragColor = vec4(0.2, 0.8, 0.2, 1.0);
}
`

main :: proc() {
	if !glfw.Init() {return}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	when ODIN_OS == .Darwin {glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)}

	window := glfw.CreateWindow(800, 600, "OpenGL 03: Rotating Triangle", nil, nil)
	if window == nil {return}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	shader_program, ok := create_shader_program(VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE)
	if !ok {return}
	defer gl.DeleteProgram(shader_program)

	vertices := [][3]f32{{-0.5, -0.5, 0.0}, {0.5, -0.5, 0.0}, {0.0, 0.5, 0.0}}

	vao, vbo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(f32) * 3, &vertices[0], gl.STATIC_DRAW)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
	gl.EnableVertexAttribArray(0)

	// Get uniform location
	transform_loc := gl.GetUniformLocation(shader_program, "transform")

	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.ClearColor(0.1, 0.1, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Create a rotation matrix
		time := f32(glfw.GetTime())
		cos_t := math.cos(time)
		sin_t := math.sin(time)

		// Column-major 4x4 rotation matrix around Z axis
		transform := [4][4]f32 {
			{cos_t, -sin_t, 0, 0},
			{sin_t, cos_t, 0, 0},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		}

		gl.UniformMatrix4fv(transform_loc, 1, gl.FALSE, &transform[0][0])

		gl.BindVertexArray(vao)
		gl.DrawArrays(gl.TRIANGLES, 0, 3)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteVertexArrays(1, &vao)
	gl.DeleteBuffers(1, &vbo)
}

// Reuse the shader creation helper (in a real app, this would be in a common file)
create_shader_program :: proc(v_source, f_source: string) -> (u32, bool) {
	compile_shader :: proc(source: string, shader_type: u32) -> (u32, bool) {
		shader := gl.CreateShader(shader_type)
		cstr := cstring(raw_data(source))
		length := i32(len(source))
		gl.ShaderSource(shader, 1, &cstr, &length)
		gl.CompileShader(shader)
		success: i32
		gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
		if success == 0 {
			info_log: [512]byte
			gl.GetShaderInfoLog(shader, 512, nil, &info_log[0])
			fmt.printf("ERROR: Shader compilation failed\n%s\n", info_log)
			return 0, false
		}
		return shader, true
	}
	v_shader, v_ok := compile_shader(v_source, gl.VERTEX_SHADER)
	f_shader, f_ok := compile_shader(f_source, gl.FRAGMENT_SHADER)
	if !v_ok || !f_ok {return 0, false}
	defer gl.DeleteShader(v_shader)
	defer gl.DeleteShader(f_shader)
	program := gl.CreateProgram()
	gl.AttachShader(program, v_shader)
	gl.AttachShader(program, f_shader)
	gl.LinkProgram(program)
	success: i32
	gl.GetProgramiv(program, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log: [512]byte
		gl.GetProgramInfoLog(program, 512, nil, &info_log[0])
		fmt.printf("ERROR: Program linking failed\n%s\n", info_log)
		return 0, false
	}
	return program, true
}
