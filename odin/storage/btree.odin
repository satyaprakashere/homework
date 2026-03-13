package btree

import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:testing"
import "core:time"

// We define the degree 'T_DEGREE' as a constant for simplicity,
// though it could be a field in the struct.
T_DEGREE :: 4
MAX_KEYS :: 2 * T_DEGREE - 1
MAX_CHILDREN :: 2 * T_DEGREE

SAMPLE_SIZE :: 1000

main :: proc() {
	tree: BTree
	init(&tree, int)
	defer free(tree.root) // Note: Proper cleanup would be recursive

	// Insert enough values to trigger multiple splits
	values: [SAMPLE_SIZE]int
	// Fill the array with random numbers between 0 and 999
	for i in 0 ..< len(values) {
		values[i] = rand.int_max(1000)
	}


	ptrs: [SAMPLE_SIZE]^int
	for i in 0 ..< len(values) {
		ptrs[i] = new_clone(values[i])
	}
	defer for p in ptrs {free(p)}

	for i in 0 ..< len(values) {
		insert(&tree, ptrs[i], compare_int)
	}

	fmt.println("Final Tree Structure:")
	pretty_print(&tree)

	fmt.println("\nSearch results:")
	for i in 0 ..< 5 {
		key_val := values[i]
		if node, idx := search(tree.root, &key_val, compare_int); node != nil {
			fmt.printf("  Found %2d at level %8v, index %d\n", key_val, node.level, idx)
		} else {
			fmt.printf("  %d not found\n", key_val)
		}
	}
}

Level :: enum i8 {
	Register = 0,
	L1Cache  = -1,
	L2Cache  = -2,
	L3Cache  = -3,
	RAM      = -4,
	SSD      = -5,
	HDD      = -6,
	Network  = -7,
}

Node :: struct {
	level:    Level,
	count:    int,
	is_leaf:  bool,
	keys:     [MAX_KEYS]rawptr, // Storing pointers to the type T
	children: [MAX_CHILDREN]^Node,
}

BTree :: struct {
	root:      ^Node,
	type_info: typeid,
	allocator: mem.Allocator,
}

// Initialize the tree
init :: proc(tree: ^BTree, $T: typeid, allocator := context.allocator) {
	tree.type_info = typeid_of(T)
	tree.allocator = allocator
	tree.root = create_node(tree, true)
}

// Helper to allocate a new node
create_node :: proc(tree: ^BTree, is_leaf: bool, level: Level = .Register) -> ^Node {
	node := new(Node, tree.allocator)
	node.is_leaf = is_leaf
	node.count = 0
	node.level = level
	return node
}

pretty_print :: proc(tree: ^BTree) {
	if tree.root == nil {
		fmt.println("Tree is empty")
		return
	}

	queue := make([dynamic]^Node, tree.allocator)
	defer delete(queue)
	append(&queue, tree.root)

	level := 0
	for len(queue) > 0 {
		level_size := len(queue)
		fmt.printf("  Level %2d: ", level)

		for _ in 0 ..< level_size {
			node := queue[0]
			ordered_remove(&queue, 0)

			fmt.print("[")
			for i in 0 ..< node.count {
				val := (cast(^int)node.keys[i])^
				fmt.print(val)
				if i < node.count - 1 {
					fmt.print(", ")
				}
			}
			fmt.print("] ")

			if !node.is_leaf {
				for i in 0 ..= node.count {
					if node.children[i] != nil {
						append(&queue, node.children[i])
					}
				}
			}
		}
		fmt.println()
		level -= 1
	}
}

compare_int :: proc(a, b: rawptr) -> int {
	va := (cast(^int)a)^
	vb := (cast(^int)b)^
	if va < vb {return -1}
	if va > vb {return 1}
	return 0
}

split_child :: proc(parent: ^Node, index: int, child: ^Node, tree: ^BTree) {
	new_node := create_node(tree, child.is_leaf, child.level)
	new_node.count = T_DEGREE - 1

	// Copy the second half of child's keys to new_node
	for j in 0 ..< T_DEGREE - 1 {
		new_node.keys[j] = child.keys[j + T_DEGREE]
	}

	// Copy the second half of child's children to new_node
	if !child.is_leaf {
		for j in 0 ..< T_DEGREE {
			new_node.children[j] = child.children[j + T_DEGREE]
		}
	}

	child.count = T_DEGREE - 1

	// Shift parent's children to make room for new_node
	for j := parent.count; j >= index + 1; j -= 1 {
		parent.children[j + 1] = parent.children[j]
	}
	parent.children[index + 1] = new_node

	// Shift parent's keys to make room for median key from child
	for j := parent.count - 1; j >= index; j -= 1 {
		parent.keys[j + 1] = parent.keys[j]
	}
	parent.keys[index] = child.keys[T_DEGREE - 1]
	parent.count += 1
}

insert_non_full :: proc(
	node: ^Node,
	key: rawptr,
	compare: proc(_: rawptr, _: rawptr) -> int,
	tree: ^BTree,
) {
	i := node.count - 1
	if node.is_leaf {
		for i >= 0 && compare(key, node.keys[i]) < 0 {
			node.keys[i + 1] = node.keys[i]
			i -= 1
		}
		node.keys[i + 1] = key
		node.count += 1
	} else {
		for i >= 0 && compare(key, node.keys[i]) < 0 {
			i -= 1
		}
		i += 1
		if node.children[i].count == MAX_KEYS {
			split_child(node, i, node.children[i], tree)
			if compare(key, node.keys[i]) > 0 {
				i += 1
			}
		}
		insert_non_full(node.children[i], key, compare, tree)
	}
}

insert :: proc(tree: ^BTree, key: rawptr, compare: proc(_: rawptr, _: rawptr) -> int) {
	root := tree.root
	if root.count == MAX_KEYS {
		new_root := create_node(tree, false, Level(i8(root.level) - 1))
		tree.root = new_root
		new_root.children[0] = root
		split_child(new_root, 0, root, tree)
		insert_non_full(new_root, key, compare, tree)
	} else {
		insert_non_full(root, key, compare, tree)
	}
}

// Search for a key
// Note: This assumes the user provides a comparison procedure
// since 'rawptr' comparisons don't know the underlying type's logic.
search :: proc(
	node: ^Node,
	key: rawptr,
	compare: proc(_: rawptr, _: rawptr) -> int,
) -> (
	^Node,
	int,
) {
	i := 0
	for i < node.count && compare(key, node.keys[i]) > 0 {
		i += 1
	}

	if i < node.count && compare(key, node.keys[i]) == 0 {
		return node, i
	}

	if node.is_leaf {
		return nil, -1
	}

	return search(node.children[i], key, compare)
}

@(test)
test_btree_1m_entries :: proc(t: ^testing.T) {
	fmt.println("\n--- B-Tree 1M Entries Test ---")

	tree: BTree
	init(&tree, int)

	count := 1_000_0
	values := make([]int, count)
	defer delete(values)

	fmt.printf("Generating %d unique-ish random values...\n", count)
	for i in 0 ..< count {
		values[i] = i
	}
	rand.shuffle(values)

	fmt.printf("Inserting %d values...\n", count)
	start_time := time.now()
	for i in 0 ..< count {
		ptr := new_clone(values[i])
		insert(&tree, ptr, compare_int)
	}
	duration := time.since(start_time)
	fmt.printf("Insertion took: %v\n", duration)

	fmt.println("Searching for 10,000 random values...")
	search_start := time.now()
	found_count := 0
	for i in 0 ..< 10_000 {
		idx := rand.int_max(count)
		key_val := values[idx]
		if node, _ := search(tree.root, &key_val, compare_int); node != nil {
			found_count += 1
		}
	}
	search_duration := time.since(search_start)
	fmt.printf("Search took: %v (Found: %d/10000)\n", search_duration, found_count)

	testing.expect(t, found_count == 10_000, "Should have found all searched keys")
}
