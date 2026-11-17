#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

// Using a large fixed stack to avoid frequent allocations
#define STACK_SIZE 104857

typedef uint64_t u64;

u64 ackermann_fast(u64 m, u64 n) {
    u64 *stack = malloc(STACK_SIZE * sizeof(u64));
    if (!stack) return 0;

    int top = 0;
    stack[top++] = m;

    while (top > 0) {
        m = stack[--top];

        if (m == 0) {
            n = n + 1;
        } else if (n == 0) {
            n = 1;
            stack[top++] = m - 1;
        } else {
            // A(m, n) = A(m-1, A(m, n-1))
            // We push m-1 first so it is processed AFTER the inner A(m, n-1)
            stack[top++] = m - 1;
            stack[top++] = m;
            n = n - 1;
        }

        if (top >= STACK_SIZE) {
            fprintf(stderr, "Stack limit exceeded!\n");
            free(stack);
            return 0;
        }
    }

    free(stack);
    return n;
}

int main() {
    u64 m = 3, n = 4;
    printf("Ackermann(%llu, %llu) = %llu\n", m, n, ackermann_fast(m, n));
    return 0;
}