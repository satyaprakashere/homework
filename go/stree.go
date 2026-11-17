//go:build ignore

package main

import (
	"errors"
	"fmt"
	"math/rand/v2"
)

func main() {
	println("Hello There!!")

	tree := initTree(100)
	fillTreeWithRandomData(tree)

	fmt.Print(tree)
}

type Node struct {
	parent int
	data   []int
}

type STree struct {
	nodes [][]struct {
		start int
		end   int
	}
}

func initTree(size uint) []Node {
	tree := make([]Node, size)

	return tree
}

func fillTreeWithRandomData(tree []Node) {
	kids := 2
	nsize := 2

	queue := RingBuffer{}
	for i := 0; i < len(tree); i++ {
		p, err := queue.dequeue()
		if err != nil {
			queue.enqueue(i)
		}

		for j := 0; j < kids && i+j < len(tree); j++ {
			tree[i+j] = Node{
				parent: p,
				data:   initRArrayfromPool(nsize),
			}
			queue.enqueue(i + j)
		}
	}
}

func initRArrayfromPool(size int) []int {
	arr := make([]int, size)

	return fillRArray(arr)
}

func fillRArray(nums []int) []int {
	for i := range nums {
		nums[i] = rand.IntN(1000)
	}
	return nums
}

type RingBuffer struct {
	data  [1024]int
	head  int
	tail  int
	count int
}

func (r *RingBuffer) enqueue(v int) {
	if r.count == 1024 {
		return
	} // Full
	r.data[r.tail] = v
	r.tail = (r.tail + 1) % 1024
	r.count++
}

func (r *RingBuffer) dequeue() (int, error) {
	if r.head < 0 {
		return 0, errors.New("Queue is empty!")
	} // Full
	v := r.data[r.head]

	r.head = (r.head + 1) % 1024
	r.count--
	return v, nil
}
