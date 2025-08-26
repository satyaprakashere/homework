#include <iostream>

using namespace std;

typedef const int32_t cint;
typedef const int64_t clong;

struct Node {
	int value;
	struct Node* left;
	struct Node* right;
	
	Node(cint data, Node* left, Node* right) {
		value = data;
		this->left = left;
		this->right = right;
	}
};

//Node* newNode(cint data, Node* left, Node* right) {
//	auto node = new Node();
//	node->left = left;
//	node->right = right;
//	return node;
//}

bool isBST(Node* tree, cint min, int max) {
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
	Node* _ = new Node(4, new Node(1, nullptr, nullptr), new Node(6, nullptr, nullptr));
}
