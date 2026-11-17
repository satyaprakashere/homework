#include <stdio.h>

void execute(void (*func)(int), int val) {
    func(val);
}

void print_val(int x) {
    printf("Value: %d\n", x);
}

int main() {
    printf("\n--- 1. Function Pointers Demo ---\n");
    execute(print_val, 42);
    return 0;
}
