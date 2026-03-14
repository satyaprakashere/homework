package algorithm

import "core:fmt"
import "core:math/rand"
import "core:mem"
import unix "core:sys/posix"
import "core:testing"
import "core:time"

T_DEGREE :: 4
// 64 Byte cache line? cache line length will depend on level
// for memory it will be page size of 4-16kb
// for HDD it will be 4-16mb? block size
MAX_KEYS :: 2 * T_DEGREE - 1
// Total cache lines
// for ref:  AMD EPYC™ 9965 (192 cores, 384 threads, 384MB L3 cache)
// depends on the size of memory of that level
// for l1 cache it will be 4000 lines of 64 bytes each (256kb l1 cache) per core
// for l2 cache it will be 64000 lines of 64 bytes each (4mb l2 cache) per core
// for l3 cache it will be 6144000 lines of 64 bytes each (384mb l3 cache)
// for ram it will be 4194304 lines of 64 bytes each (256gb ram)
// for ssd it will be 2097152 lines of 4kb each (8tb ssd)
// for hdd it will be 16777216 lines of 4kb each (64tb hdd)
// for network it will be 67108864 lines of 4kb each (256tb network)
// for archive it will be 268435456 lines of 4kb each (1024tb archive)
MAX_CHILDREN :: 2 * T_DEGREE

SAMPLE_SIZE :: 1_000_000
TEST_SAMPLE_SIZE :: 1_000_000

M2_PRO :: struct {
	l1_cache: [128_000]u8,
	l2_cache: [4_096_000]u8,
	l3_cache: [24_000_000]u8,
	ram:      [16_000_000_000]u8,
	ssd:      [512_000_000_000]u8,
	hdd:      [4_000_000_000_000]u8,
	network:  [8_000_000_000_000]u8,
	archive:  [8_000_000_000_000]u8,
}

main :: proc() {
	fmt.println("--- B-Tree Min Heap Demo ---")

	tree: BTree(int)
	init(&tree)

	// Small demo
	values := [SAMPLE_SIZE]int{}
	for i in 0 ..< SAMPLE_SIZE {
		values[i] = rand.int_max(1_000_000 * 10)
		insert(&tree, values[i])
	}

	fmt.println("Tree Structure (limited depth):")
	pretty_print(&tree)

	fmt.println("\nSearch results:")
	for i in 0 ..< 5 {
		key_val := values[i]
		if node, idx := search(tree.root, key_val); node != nil {
			fmt.printf("  Found %3d at level %2d, index %d\n", key_val, node.level, idx)
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
	Archive  = -8,
}

Node :: struct($T: typeid) {
	children: [MAX_CHILDREN]^Node(T),
	keys:     [MAX_KEYS]T,
	count:    u8,
	level:    Level,
	is_leaf:  bool,
}

BTree :: struct($T: typeid) {
	root:      ^Node(T),
	allocator: mem.Allocator,
}

init :: proc(tree: ^BTree($T), allocator := context.allocator) {
	tree.allocator = allocator
	tree.root = create_node(tree, true)
}

pretty_print :: proc(tree: ^BTree($T)) {
	if tree.root == nil {
		fmt.println("Tree is empty")
		return
	}

	queue := make([dynamic]^Node(T), tree.allocator)
	defer delete(queue)
	append(&queue, tree.root)

	level := 0
	for len(queue) > 0 && level > -4 {
		level_size := len(queue)
		fmt.printf("  Level %2d: ", level)

		for _ in 0 ..< level_size {
			node := queue[0]
			ordered_remove(&queue, 0)

			fmt.print("[")
			for i in 0 ..< int(node.count) {
				val := node.keys[i]
				fmt.print(val)
				if i < int(node.count) - 1 {
					fmt.print(", ")
				}
			}
			fmt.print("] ")

			if !node.is_leaf {
				for i in 0 ..= int(node.count) {
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

create_node :: proc(tree: ^BTree($T), is_leaf: bool, level: Level = .Register) -> ^Node(T) {
	node := new(Node(T), tree.allocator)
	node.is_leaf = is_leaf
	node.count = 0
	node.level = level
	return node
}

split_child :: proc(parent: ^Node($T), index: int, child: ^Node(T), tree: ^BTree(T)) {
	new_node := create_node(tree, child.is_leaf, child.level)
	new_node.count = T_DEGREE - 1
	for j in 0 ..< T_DEGREE - 1 {
		new_node.keys[j] = child.keys[j + T_DEGREE]
	}
	if !child.is_leaf {
		for j in 0 ..< T_DEGREE {
			new_node.children[j] = child.children[j + T_DEGREE]
		}
	}
	child.count = T_DEGREE - 1
	for j := int(parent.count); j >= index + 1; j -= 1 {
		parent.children[j + 1] = parent.children[j]
	}
	parent.children[index + 1] = new_node
	for j := int(parent.count) - 1; j >= index; j -= 1 {
		parent.keys[j + 1] = parent.keys[j]
	}
	parent.keys[index] = child.keys[T_DEGREE - 1]
	parent.count += 1
}

insert_non_full :: proc(node: ^Node($T), key: T, tree: ^BTree(T)) {
	i := int(node.count) - 1
	if node.is_leaf {
		for i >= 0 && key < node.keys[i] {
			node.keys[i + 1] = node.keys[i]
			i -= 1
		}
		node.keys[i + 1] = key
		node.count += 1
	} else {
		for i >= 0 && key < node.keys[i] {
			i -= 1
		}
		i += 1
		if node.children[i].count == MAX_KEYS {
			split_child(node, i, node.children[i], tree)
			if key > node.keys[i] {
				i += 1
			}
		}
		insert_non_full(node.children[i], key, tree)
	}
}

insert :: proc(tree: ^BTree($T), key: T) {
	root := tree.root
	if root.count == MAX_KEYS {
		new_root := create_node(tree, false, Level(i8(root.level) - 1))
		tree.root = new_root
		new_root.children[0] = root
		split_child(new_root, 0, root, tree)
		insert_non_full(new_root, key, tree)
	} else {
		insert_non_full(root, key, tree)
	}
}

search :: proc(node: ^Node($T), key: T) -> (^Node(T), int) {
	i := 0
	for i < int(node.count) && key > node.keys[i] {
		i += 1
	}
	if i < int(node.count) && key == node.keys[i] {
		return node, i
	}
	if node.is_leaf {
		return nil, -1
	}
	return search(node.children[i], key)
}

@(test)
test_btree_1m_entries_nopointers :: proc(t: ^testing.T) {
	fmt.println("\n--- B-Tree 1M Entries Test (No Pointers, with Arena Reserve) ---")

	// Reserve memory. For 1M ints, 256MB is plenty.
	// Each Node(int) is ~16 bytes header + (7 * 8) keys + (8 * 8) pointers = ~136 bytes.
	// 1M / 4 (avg keys per node) * 136 bytes = ~34MB.
	arena_size: uint = 256 * TEST_SAMPLE_SIZE
	data := unix.mmap(nil, arena_size, {.READ, .WRITE}, {.PRIVATE, .ANONYMOUS}, -1, 0)
	if data == nil {
		fmt.println("Failed to reserve memory via mmap")
		return
	}
	defer unix.munmap(data, arena_size)

	data_slice := ([^]u8)(data)[:arena_size]
	arena: mem.Arena
	mem.arena_init(&arena, data_slice)
	allocator := mem.arena_allocator(&arena)

	tree: BTree(int)
	init(&tree, allocator)

	values := make([]int, TEST_SAMPLE_SIZE)
	defer delete(values)

	fmt.printf("Generating %d random values...\n", TEST_SAMPLE_SIZE)
	for i in 0 ..< TEST_SAMPLE_SIZE {
		values[i] = rand.int_max(TEST_SAMPLE_SIZE * 10)
	}

	fmt.printf("Inserting %d values...\n", TEST_SAMPLE_SIZE)
	start_time := time.now()
	for i in 0 ..< TEST_SAMPLE_SIZE {
		insert(&tree, values[i])
	}
	duration := time.since(start_time)
	fmt.printf("Insertion took: %v\n", duration)

	fmt.println("Searching for 10,000 random values...")
	search_start := time.now()
	found_count := 0
	for i in 0 ..< 10_000 {
		idx := rand.int_max(TEST_SAMPLE_SIZE)
		if node, _ := search(tree.root, values[idx]); node != nil {
			found_count += 1
		}
	}
	search_duration := time.since(search_start)
	fmt.printf("Search took: %v (Found: %d/10000)\n", search_duration, found_count)

	testing.expect(t, found_count == 10_000, "Should have found all 10,000 searched keys")
}
