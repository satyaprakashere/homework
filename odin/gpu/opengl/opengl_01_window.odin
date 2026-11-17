package main

import "core:fmt"
import "vendor:glfw"
import gl "vendor:OpenGL"

/*
	OPENGL_01: HELLO WINDOW

	This example demonstrates the basics of setting up a window using GLFW
	and initializing an OpenGL context.
*/

main :: proc() {
	// 1. Initialize GLFW
	if !glfw.Init() {
		fmt.println("Failed to initialize GLFW")
		return
	}
	defer glfw.Terminate()

	// 2. Set GLFW window hints (OpenGL version 3.3 Core Profile)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	// Mac requires forward compatibility
	when ODIN_OS == .Darwin {
		glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, gl.TRUE)
	}

	// 3. Create a window
	window := glfw.CreateWindow(800, 600, "OpenGL 01: Hello Window", nil, nil)
	if window == nil {
		fmt.println("Failed to create GLFW window")
		return
	}
	defer glfw.DestroyWindow(window)

	// 4. Make the OpenGL context current
	glfw.MakeContextCurrent(window)
	
	// 5. Load OpenGL functions
	gl.load_up_to(3, 3, glfw.gl_set_proc_address)

	fmt.println("OpenGL Context initialized:")
	fmt.printf("  Vendor:   %s\n", gl.GetString(gl.VENDOR))
	fmt.printf("  Renderer: %s\n", gl.GetString(gl.RENDERER))
	fmt.printf("  Version:  %s\n", gl.GetString(gl.VERSION))

	// 6. Main loop
	for !glfw.WindowShouldClose(window) {
		// Process input
		if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
			glfw.SetWindowShouldClose(window, true)
		}

		// Render: Clear the screen with a nice dark gray-blue color
		gl.ClearColor(0.2, 0.3, 0.3, 1.0)
		gl.Clear(gl.COLOR_BUFFER_BIT)

		// Swap buffers and poll events
		glfw.SwapBuffers(window)
		glfw.PollEvents()
	}
}
