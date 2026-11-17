package main

import "core:fmt"
import "core:mem"

// --- Domain Specific: Math Expressions ---

Expr_F :: struct {
	variant: union {
		Lit,
		Add,
		Mul,
	},
}

Lit :: struct {
	val: f64,
}
Add :: struct {
	left, right: int,
}
Mul :: struct {
	left, right: int,
}

eval_algebra :: proc(node: Expr_F, results: []f64) -> f64 {
	switch v in node.variant {
	case Lit:
		return v.val
	case Add:
		return results[v.left] + results[v.right]
	case Mul:
		return results[v.left] * results[v.right]
	}
	return 0
}

// --- Example Usage ---

main :: proc() {
	fmt.println("Recursion Schemes in Odin (Tail Call & Pre-allocated)")

	// 1. Catamorphism with Pre-allocated memory
	{
		nodes_buf: [16]Expr_F
		results_buf: [16]f64

		store := Store(Expr_F) {
			nodes = nodes_buf[:],
			count = 0,
		}

		store.nodes[0] = Expr_F {
			variant = Lit{10},
		}
		store.nodes[1] = Expr_F {
			variant = Lit{20},
		}
		store.nodes[2] = Expr_F {
			variant = Add{0, 1},
		}
		store.count = 3

		result := cata(store, results_buf[:], eval_algebra)
		fmt.printf("Cata Result: 10 + 20 = %v\n", result)
	}

	// 2. Performance Verification: Zero Allocation
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		nodes_buf: [100]Expr_F
		results_buf: [100]f64

		store := Store(Expr_F) {
			nodes = nodes_buf[:],
			count = 0,
		}

		store.nodes[0] = Expr_F {
			variant = Lit{1},
		}
		for i in 1 ..< 100 {
			store.nodes[i] = Expr_F {
				variant = Add{i - 1, 0},
			}
		}
		store.count = 100

		result := cata(store, results_buf[:], eval_algebra)
		fmt.printf("Chain Result (100 nodes): %v\n", result)

		if len(track.allocation_map) == 0 {
			fmt.println("Verification SUCCESS: Zero dynamic allocations!")
		} else {
			fmt.println("Verification FAILURE: Dynamic allocations detected.")
		}
	}

	// 3. Hylomorphism: Factorial(5)
	{
		nodes_buf: [16]Expr_F
		results_buf: [16]f64
		seeds_buf: [16]int

		store := Store(Expr_F) {
			nodes = nodes_buf[:],
			count = 0,
		}
		seeds_count := 0

		fact_coalg :: proc(seed: int, children: ^[]int, children_count: ^int) -> Expr_F {
			if seed <= 1 {
				return Expr_F{variant = Lit{1}}
			} else {
				children[0] = seed - 1
				children_count^ = 1
				return Expr_F{variant = Mul{0, 0}}
			}
		}

		fact_alg_linear := proc(node: Expr_F, results: []f64) -> f64 {
			// Find current index
			i := 0
			for i < 16 && results[i] != 0 {i += 1}

			switch v in node.variant {
			case Lit:
				return v.val
			case Mul:
				if i == 0 do return 1
				return f64(i + 1) * results[i - 1]
			case Add:
				return 0
			}
			return 0
		}

		result := hylo(
			&store,
			results_buf[:],
			seeds_buf[:],
			&seeds_count,
			5,
			nil,
			fact_coalg,
			fact_alg_linear,
		)
		fmt.printf("Hylo Factorial(5) = %v\n", result)
	}
}
