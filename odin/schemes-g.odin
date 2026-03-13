package main

import "core:fmt"
import "core:mem"

// --- 1. THE DATA SHAPE ---

// The "Base Functor". T is the type of the recursive sub-nodes.
ExprF :: struct($T: typeid) {
	variant: union {
		int,
		BinaryOP(T),
	},
}

BinaryOP :: struct($T: typeid) {
	left, right: T,
	op:          u8,
}

// --- 2. THE FIXED POINT ---

// This is our "Recursive Knot".
// We define a concrete type 'Expr' to avoid polymorphic literal errors.
Expr :: struct {
	derived: ExprF(^Expr),
}

// Helper to allocate a new node in the Arena
new_node :: proc(allocator: mem.Allocator, val: ExprF(^Expr)) -> ^Expr {
	p, _ := mem.new(Expr, allocator)
	p.derived = val
	return p
}

// --- 3. THE CATAMORPHISM ---

// cata: (ExprF(A) -> A) -> Expr -> A
// It collapses the recursive 'Expr' into a single value 'A'.
cata :: proc(node: ^Expr, algebra: proc(_: ExprF($A)) -> A) -> A {
	// 1. Recurse down: map 'cata' over children to turn them into 'A'
	mapped_layer: ExprF(A)

	switch v in node.derived.variant {
	case int:
		mapped_layer.variant = v
	case BinaryOP(^Expr):
		mapped_layer.variant = BinaryOP(A) {
			left  = cata(v.left, algebra),
			right = cata(v.right, algebra),
			op    = v.op,
		}
	}

	// 2. Apply algebra to the results
	return algebra(mapped_layer)
}

// --- 4. THE LOGIC (Algebra) ---

eval_algebra :: proc(e: ExprF(int)) -> int {
	switch v in e.variant {
	case int:
		return v
	case BinaryOP(int):
		switch v.op {
		case '+':
			return v.left + v.right
		case '*':
			return v.left * v.right
		}
	}
	return 0
}

// --- 5. MAIN ---

main :: proc() {
	// Initialize Arena
	arena_buffer := make([]byte, 1 * 1024 * 1024)
	defer delete(arena_buffer)

	arena: mem.Arena
	mem.arena_init(&arena, arena_buffer)
	alloc := mem.arena_allocator(&arena)

	fmt.println("--- Fixed-Point Recursion with Arena ---")

	// Building the tree: (10 + 20) * 2
	// Note how much cleaner 'new_node' is than nested polymorphic literals.

	ten := new_node(alloc, ExprF(^Expr){variant = 10})
	twenty := new_node(alloc, ExprF(^Expr){variant = 20})

	inner_add := new_node(
		alloc,
		ExprF(^Expr){variant = BinaryOP(^Expr){left = ten, right = twenty, op = '+'}},
	)

	root := new_node(
		alloc,
		ExprF(^Expr) {
			variant = BinaryOP(^Expr) {
				left = inner_add,
				right = new_node(alloc, ExprF(^Expr){variant = 2}),
				op = '*',
			},
		},
	)

	// Run the Catamorphism
	result := cata(root, eval_algebra)
	fmt.printfln("Final Result: %d", result)

	// The Arena allows us to free every node in the tree at once
	// by simply letting the 'arena_buffer' be deleted or resetting the arena.
}
