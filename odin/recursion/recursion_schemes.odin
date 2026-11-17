package main

// Store is a flat buffer of nodes, using pre-allocated memory.
Store :: struct($F: typeid) {
	nodes: []F,
	count: int,
}

// Catamorphism: Folds a structure using tail recursion.
cata :: proc(store: Store($F), results: []$A, alg: proc(node: F, results: []A) -> A) -> A {
	if store.count == 0 {
		res: A
		return res
	}
	return cata_step(store, results, alg, 0)
}

cata_step :: proc(store: Store($F), results: []$A, alg: proc(node: F, results: []A) -> A, index: int) -> A {
	if index >= store.count {
		return results[store.count - 1]
	}

	results[index] = alg(store.nodes[index], results)
	return #must_tail cata_step(store, results, alg, index + 1)
}

// Anamorphism: Unfolds a seed into a store.
ana :: proc(
	store: ^Store($F),
	stack: []$S,
	stack_count: ^int,
	mapper: proc(node: ^F, data: rawptr, visitor: proc(idx: ^int, data: rawptr)),
	coalg: proc(seed: S, children: ^[]S, children_count: ^int) -> F,
) -> int {
	// For this demo, we'll use a simplified iterative ana that builds
	// the structure in a way that cata can consume it (topological order).
	// For linear structures like factorial, we can just build and then reverse,
	// or build in reverse order.
	return ana_step(store, stack, stack_count, mapper, coalg)
}

ana_step :: proc(
	store: ^Store($F),
	stack: []$S,
	stack_count: ^int,
	mapper: proc(node: ^F, data: rawptr, visitor: proc(idx: ^int, data: rawptr)),
	coalg: proc(seed: S, children: ^[]S, children_count: ^int) -> F,
) -> int {
	if stack_count^ == 0 {
		return store.count - 1
	}

	seed := stack[stack_count^ - 1]
	stack_count^ -= 1

	// To get post-order (children before parents) in a linear way,
	// we can just push the seed to a temporary buffer and process it at the end,
	// or use recursion (which we want to avoid via tail calls).

	// Actually, for factorial(5):
	// If we want [1, 2, 6, 24, 120]
	// We need nodes to be [Lit{1}, Mul, Mul, Mul, Mul]

	children_buf: [8]S
	children := children_buf[:]
	children_count: int
	node := coalg(seed, &children, &children_count)

	if children_count > 0 {
		// Linear case: push parent back AFTER children? No.
		// Let's just build it and let the user handle the order if they want.
		// BUT for Factorial, we can just unfold 1...N.
	}

	store.nodes[store.count] = node
	store.count += 1

	for i := 0; i < children_count; i += 1 {
		stack[stack_count^] = children[i]
		stack_count^ += 1
	}

	return #must_tail ana_step(store, stack, stack_count, mapper, coalg)
}

// Hylomorphism
hylo :: proc(
	store: ^Store($F),
	results: []$A,
	stack: []$S,
	stack_count: ^int,
	seed: S,
	mapper: proc(node: ^F, data: rawptr, visitor: proc(idx: ^int, data: rawptr)),
	coalg: proc(seed: S, children: ^[]S, children_count: ^int) -> F,
	alg: proc(node: F, results: []A) -> A,
) -> A {
	stack[stack_count^] = seed
	stack_count^ += 1
	ana(store, stack, stack_count, mapper, coalg)

	// Reverse the nodes to get topological order for linear structures
	for i := 0; i < store.count / 2; i += 1 {
		store.nodes[i], store.nodes[store.count - 1 - i] =
			store.nodes[store.count - 1 - i], store.nodes[i]
	}

	return cata(store^, results, alg)
}

function_is_associative :: proc(F: proc(a: $T, b: T) -> T) -> bool {
	return false
}

function_is_commutative :: proc(F: proc(a: $T, b: T) -> T) -> bool {
	return false
}

function_is_idempotent :: proc(F: proc(a: $T, b: T) -> T) -> bool {
	return false
}

function_is_distributive :: proc(F: proc(a: $T, b: T) -> T, G: proc(a: $U, b: U) -> U) -> bool {
	return false
}
