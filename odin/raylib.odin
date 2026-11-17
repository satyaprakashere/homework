package main

import "vendor:raylib"

main :: proc() {
	// 1. Initialization
	screen_width: i32 = 854
	screen_height: i32 = 480

	raylib.InitWindow(screen_width, screen_height, "Odin + Raylib: Metal Triangle")
	defer raylib.CloseWindow() // Ensures clean exit

	raylib.SetTargetFPS(60)

	// 2. Main Game Loop
	for !raylib.WindowShouldClose() {
		// Update logic goes here (if any)

		// 3. Rendering
		raylib.BeginDrawing()
		raylib.ClearBackground(raylib.SKYBLUE)

		// Define the triangle points
		v1 := raylib.Vector2{f32(screen_width) / 2, 80}
		v2 := raylib.Vector2{f32(screen_width) / 2 - 150, 350}
		v3 := raylib.Vector2{f32(screen_width) / 2 + 150, 350}

		raylib.DrawTriangle(v1, v2, v3, raylib.BEIGE)

		raylib.DrawText("", 10, 10, 20, raylib.DARKGRAY)

		raylib.EndDrawing()
	}
}
