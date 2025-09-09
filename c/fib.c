#include <stdio.h>

typedef unsigned int uint;
typedef unsigned long ulong;

ulong fib_tail(ulong n, ulong a, ulong b) {
    if (n == 0) return a;
    return fib_tail(n - 1, b, a + b);
}

ulong fib(uint n) {
    return fib_tail(n, 0, 1);
}

int main() {
    int n = 987654321;
    printf("fib(%u) = %lu \n", n, fib(n));  // Output: fib(10) = 55

    int x[3] = {1, 2, 4};
    printf("%d", x[1]);

    int size = 0;
    scanf("%d", &size);

    int y[size];

    printf("%d", y[1]);
}
