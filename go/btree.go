//go:build ignore

package main

import (
	"fmt"
)

// Node represents a node in the B-Tree
type Node struct {
	keys     []int
	children []*Node
	isLeaf   bool
}

// BTree represents the B-Tree structure
type BTree struct {
	root *Node
	t    int // Minimum degree (defines the range for number of keys)
}

func main() {
	// Create a B-Tree with minimum degree 4
	// Each node can have 3 to 7 keys
	tree := NewBTree(4)

	keys := []int{10, 20, 5, 6, 12, 30, 7, 17, 25, 35, 45, 55, 65, 75, 85, 95, 105, 115, 125, 135, 145, 155, 165, 175, 185, 195, 205, 215, 225, 235, 245, 255, 265, 275, 285, 295, 305, 315, 325, 335, 345, 355, 365, 375, 385, 395, 405, 415, 425, 435, 445, 455, 465, 475, 485, 495, 505, 515, 525, 535, 545, 555, 565, 575, 585, 595, 605, 615, 625, 635, 645, 655, 665, 675, 685, 695, 705, 715, 725, 735, 745, 755, 765, 775, 785, 795, 805, 815, 825, 835, 845, 855, 865, 875, 885, 895, 905, 915, 925, 935, 945, 955, 965, 975, 985, 995}
	fmt.Println("Inserting keys:", keys)
	for _, key := range keys {
		tree.Insert(key)
	}

	fmt.Println("\nB-Tree structure:")
	tree.Print()

	// Search for keys
	searchKey := 6
	fmt.Printf("\nSearching for key %d: ", searchKey)
	if node := tree.Search(searchKey); node != nil {
		fmt.Println("Found in node with keys:", node.keys)
	} else {
		fmt.Println("Not found")
	}

	searchKey = 15
	fmt.Printf("Searching for key %d: ", searchKey)
	if node := tree.Search(searchKey); node != nil {
		fmt.Println("Found in node with keys:", node.keys)
	} else {
		fmt.Println("Not found")
	}
}

// NewBTree creates a new B-Tree with the given minimum degree
func NewBTree(t int) *BTree {
	return &BTree{
		t:    t,
		root: &Node{isLeaf: true},
	}
}

// Search searches for a key in the B-Tree
func (t *BTree) Search(k int) *Node {
	return search(t.root, k)
}

// search is a recursive helper function for searching
func search(x *Node, k int) *Node {
	i := 0
	for i < len(x.keys) && k > x.keys[i] {
		i++
	}

	if i < len(x.keys) && k == x.keys[i] {
		return x
	}

	if x.isLeaf {
		return nil
	}

	return search(x.children[i], k)
}

// Insert inserts a key into the B-Tree
func (t *BTree) Insert(k int) {
	r := t.root
	if len(r.keys) == (2*t.t)-1 {
		s := &Node{isLeaf: false}
		s.children = append(s.children, r)
		t.root = s
		splitChild(s, 0, r)
		insertNonFull(s, k, t.t)
	} else {
		insertNonFull(r, k, t.t)
	}
}

// insertNonFull inserts a key into a non-full node
func insertNonFull(x *Node, k int, t int) {
	i := len(x.keys) - 1
	if x.isLeaf {
		x.keys = append(x.keys, 0) // Make space
		for i >= 0 && k < x.keys[i] {
			x.keys[i+1] = x.keys[i]
			i--
		}
		x.keys[i+1] = k
	} else {
		for i >= 0 && k < x.keys[i] {
			i--
		}
		i++
		if len(x.children[i].keys) == (2*t)-1 {
			splitChild(x, i, x.children[i])
			if k > x.keys[i] {
				i++
			}
		}
		insertNonFull(x.children[i], k, t)
	}
}

// splitChild splits a full child node
func splitChild(x *Node, i int, y *Node) {
	t := (len(y.keys) + 1) / 2
	z := &Node{isLeaf: y.isLeaf}

	// Copy the second half of keys from y to z
	z.keys = make([]int, t-1)
	copy(z.keys, y.keys[t:])

	// If y is not a leaf, copy the second half of children from y to z
	if !y.isLeaf {
		z.children = make([]*Node, t)
		copy(z.children, y.children[t:])
	}

	// Insert the middle key of y into x
	midKey := y.keys[t-1]

	// Reduce the number of keys in y
	y.keys = y.keys[:t-1]

	// Insert z as a new child of x
	// Shift children to make space for z
	newChildren := make([]*Node, len(x.children)+1)
	copy(newChildren, x.children[:i+1])
	newChildren[i+1] = z
	copy(newChildren[i+2:], x.children[i+1:])
	x.children = newChildren

	// Insert the middle key of y into x
	newKeys := make([]int, len(x.keys)+1)
	copy(newKeys, x.keys[:i])
	newKeys[i] = midKey
	copy(newKeys[i+1:], x.keys[i:])
	x.keys = newKeys
}

// Print prints the B-Tree in a structured way
func (t *BTree) Print() {
	printTree(t.root, 0)
}

// printTree is a recursive helper for printing
func printTree(x *Node, level int) {
	fmt.Printf("Level %d: ", level)
	for i, key := range x.keys {
		fmt.Printf("%d ", key)
		if i < len(x.children)-1 {
			fmt.Printf("(child) ")
		}
	}
	fmt.Println()

	if !x.isLeaf {
		for _, child := range x.children {
			printTree(child, level+1)
		}
	}
}
