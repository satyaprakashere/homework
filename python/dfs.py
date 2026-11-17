def dfs(tree):
	if tree.left is not None:
		dfs(tree.left)
	if tree.value is not None:
		print(tree.value)
	if tree.right is not None:
		dfs(tree.right)

class Tree:
	def __init__(self, value, left, right):
		self.value = value
		self.left = left
		self.right = right

tree = Tree(5, Tree(7, None, Tree(3, None, None)), Tree(4, None, None))
print(dfs(tree))