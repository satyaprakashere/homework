package main

import "core:fmt"
import "core:slice"

// A simple coordinate point
Pos :: [2]int

ASNode :: struct {
	pos:    Pos,
	g_cost: f32, // Distance from start
	h_cost: f32, // Estimated distance to goal
	f_cost: f32, // Total cost (g + h)
	parent: ^ASNode,
}

main :: proc() {
	start := Pos{0, 0}
	goal := Pos{5, 5}
	path := find_path(start, goal, 10, 10)
	defer delete(path)

	fmt.print("Path found: ")
	for p in path {
		fmt.printf("[%d, %d] -> ", p.x, p.y)
	}
	fmt.println("Goal!")
}

// Manhattan distance for grid-based movement
heuristic :: proc(a, b: Pos) -> f32 {
	return f32(abs(a.x - b.x) + abs(a.y - b.y))
}

find_path :: proc(start, goal: Pos, grid_width, grid_height: int) -> []Pos {
	open_set := make([dynamic]^ASNode)
	closed_set := make(map[Pos]bool)
	// Keep track of all allocated nodes to clean up later
	all_nodes := make(map[Pos]^ASNode)

	defer {
		for _, n in all_nodes {free(n)}
		delete(all_nodes)
		delete(open_set)
		delete(closed_set)
	}

	start_node := new(ASNode)
	start_node.pos = start
	start_node.h_cost = heuristic(start, goal)
	start_node.f_cost = start_node.h_cost

	append(&open_set, start_node)
	all_nodes[start] = start_node

	for len(open_set) > 0 {
		// 1. Get node with lowest F cost
		// In a production app, use a Priority Queue (Min-Heap) here
		current_idx := 0
		for i in 1 ..< len(open_set) {
			if open_set[i].f_cost < open_set[current_idx].f_cost {
				current_idx = i
			}
		}

		current := open_set[current_idx]

		// 2. Check if we reached the goal
		if current.pos == goal {
			return reconstruct_path(current)
		}

		// 3. Move current from open to closed
		unordered_remove(&open_set, current_idx)
		closed_set[current.pos] = true

		// 4. Check neighbors (Up, Down, Left, Right)
		neighbors := [4]Pos {
			{current.pos.x, current.pos.y + 1},
			{current.pos.x, current.pos.y - 1},
			{current.pos.x + 1, current.pos.y},
			{current.pos.x - 1, current.pos.y},
		}

		for next_pos in neighbors {
			// Boundary checks
			if next_pos.x < 0 ||
				next_pos.x >= grid_width ||
				next_pos.y < 0 ||
				next_pos.y >= grid_height {
				continue
			}

			if next_pos in closed_set do continue

			tentative_g := current.g_cost + 1 // Cost of 1 to move to neighbor

			neighbor, exists := all_nodes[next_pos]

			if !exists {
				neighbor = new(ASNode)
				neighbor.pos = next_pos
				all_nodes[next_pos] = neighbor
			}

			if !slice.contains(open_set[:], neighbor) || tentative_g < neighbor.g_cost {
				neighbor.parent = current
				neighbor.g_cost = tentative_g
				neighbor.h_cost = heuristic(next_pos, goal)
				neighbor.f_cost = neighbor.g_cost + neighbor.h_cost

				if !slice.contains(open_set[:], neighbor) {
					append(&open_set, neighbor)
				}
			}
		}
	}
	return nil // No path found
}

reconstruct_path :: proc(end_node: ^ASNode) -> []Pos {
	path := make([dynamic]Pos)
	curr := end_node
	for curr != nil {
		append(&path, curr.pos)
		curr = curr.parent
	}
	// Path is generated backwards, so reverse it
	slice.reverse(path[:])
	return path[:]
}
