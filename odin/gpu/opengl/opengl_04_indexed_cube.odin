package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"
import "vendor:glfw"

/*
    OPENGL_04: INDEXED CUBE (3D)
    
    This example covers:
    - Element Buffer Objects (EBO) for indexed drawing.
    - 3D transformations (Model, View, Projection).
    - Using core:math/linalg for linear algebra.
    - Depth testing.
*/

VERTEX_SHADER := `
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aColor;

out vec3 ourColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    ourColor = aColor;
}
`

FRAGMENT_SHADER := `
#version 330 core
out vec4 FragColor;
in vec3 ourColor;
void main() {
    FragColor = vec4(ourColor, 1.0);
}
`

Vertex :: struct {
	pos:   [3]f32,
	color: [3]f32,
}

main :: proc() {
	if !glfw.Init() {return}
	defer glfw.Terminate()

	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	when ODIN_OS == .Darwin {glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)}

	window := glfw.CreateWindow(800, 600, "OpenGL 04: Indexed Cube", nil, nil)
	if window == nil {return}
	defer glfw.DestroyWindow(window)

	glfw.MakeContextCurrent(window)
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	// Enable depth testing for 3D
	gl.Enable(gl.DEPTH_TEST)

	shader_program, ok := create_shader_program(VERTEX_SHADER, FRAGMENT_SHADER)
	if !ok {return}
	defer gl.DeleteProgram(shader_program)

	// Define cube vertices (positions and colors)
	vertices := []Vertex {
		// Front face
		{{-0.5, -0.5, 0.5}, {1, 0, 0}},
		{{0.5, -0.5, 0.5}, {0, 1, 0}},
		{{0.5, 0.5, 0.5}, {0, 0, 1}},
		{{-0.5, 0.5, 0.5}, {1, 1, 0}},
		// Back face
		{{-0.5, -0.5, -0.5}, {1, 0, 1}},
		{{0.5, -0.5, -0.5}, {0, 1, 1}},
		{{0.5, 0.5, -0.5}, {1, 1, 1}},
		{{-0.5, 0.5, -0.5}, {0, 0, 0}},
	}

	indices := []u32 {
		0,
		1,
		2,
		2,
		3,
		0, // front
		1,
		5,
		6,
		6,
		2,
		1, // right
		7,
		6,
		5,
		5,
		4,
		7, // back
		4,
		0,
		3,
		3,
		7,
		4, // left
		4,
		5,
		1,
		1,
		0,
		4, // bottom
		3,
		2,
		6,
		6,
		7,
		3, // top
	}

	vao, vbo, ebo: u32
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(Vertex), &vertices[0], gl.STATIC_DRAW)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(
		gl.ELEMENT_ARRAY_BUFFER,
		len(indices) * size_of(u32),
		&indices[0],
		gl.STATIC_DRAW,
	)

	// Position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, pos))
	gl.EnableVertexAttribArray(0)
	// Color attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, color))
	gl.EnableVertexAttribArray(1)

	model_loc := gl.GetUniformLocation(shader_program, "model")
	view_loc := gl.GetUniformLocation(shader_program, "view")
	proj_loc := gl.GetUniformLocation(shader_program, "projection")

	for !glfw.WindowShouldClose(window) {
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		gl.ClearColor(0.05, 0.05, 0.1, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

		gl.UseProgram(shader_program)

		// Create matrices
		time := f32(glfw.GetTime())

		model := linalg.matrix4_rotate_f32(time, {0.5, 1, 0})
		view := linalg.matrix4_translate_f32({0, 0, -3})
		proj := linalg.matrix4_perspective_f32(math.to_radians_f32(45), 800.0 / 600.0, 0.1, 100.0)

		gl.UniformMatrix4fv(model_loc, 1, gl.FALSE, &model[0][0])
		gl.UniformMatrix4fv(view_loc, 1, gl.FALSE, &view[0][0])
		gl.UniformMatrix4fv(proj_loc, 1, gl.FALSE, &proj[0][0])

		gl.BindVertexArray(vao)
		gl.DrawElements(gl.TRIANGLES, i32(len(indices)), gl.UNSIGNED_INT, nil)

		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}

	gl.DeleteVertexArrays(1, &vao)
	gl.DeleteBuffers(1, &vbo)
	gl.DeleteBuffers(1, &ebo)
}

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
