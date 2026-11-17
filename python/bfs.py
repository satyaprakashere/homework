#!/usr/bin/env python3
import queue

def bfs(tree):
    q = queue.Queue()

    if tree is not None:
        q.put(tree)

    while(not q.empty()):
        node = q.get()
        if node.value is not None:
            print(node.value)
        if node.left is not None:
            q.put(node.left)
        if node.right is not None:
            q.put(node.right)

class Tree:
    def __init__(self, value, left, right):
        self.value = value
        self.left = left
        self.right = right

tree = Tree(5, Tree(7, None,
        Tree(3, None,
            Tree(9, None,
                None))),
        Tree(4, None,
            Tree(10, None,
                None)))

print(bfs(tree))
