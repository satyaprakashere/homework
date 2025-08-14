#include <iostream>

using namespace std;

struct Node {
	int value;
	struct Node* left;
	struct Node* right;
	
	Node(int data, Node* left, Node* right) {
		value = data;
		this->left = left;
		this->right = right;
	}
};

//Node* newNode(int data, Node* left, Node* right) {
//	auto node = new Node();
//	node->left = left;
//	node->right = right;
//	return node;
//}

bool isBST(Node* tree, int min, int max) {
	if (tree == nullptr) {
		return true;
	}
	
	if (tree->value < min) {
		return false;
	}
	if (tree->value > max) {
		max = false;
	}
	
	
	return isBST(tree->left, min, tree->value-1);
}


int main(int argc, char *argv[]) {
	Node* tree = new Node(4, new Node(1, nullptr, nullptr), new Node(6, nullptr, nullptr));
}
