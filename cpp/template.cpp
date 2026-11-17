#include <iostream>

using namespace std;

template <typename T>
T add(T a, T b) {
	return a + b;
}

int main(int argc, char *argv[]) {
	println("Hello There!");
	cout << add(8, 9) << endl;
}