-module(recursion).
-export([factorial/1, tail_factorial/1, fibonacci/1, sum/1]).

%% Basic recursion
factorial(0) -> 1;
factorial(N) when N > 0 -> N * factorial(N - 1).

%% Tail-recursive factorial
tail_factorial(N) -> tail_factorial(N, 1).
tail_factorial(0, Acc) -> Acc;
tail_factorial(N, Acc) when N > 0 -> tail_factorial(N - 1, N * Acc).

%% Fibonacci (not efficient, but demonstrates multiple clauses)
fibonacci(0) -> 0;
fibonacci(1) -> 1;
fibonacci(N) when N > 1 -> fibonacci(N - 1) + fibonacci(N - 2).

%% List summation using recursion
sum([]) -> 0;
sum([H|T]) -> H + sum(T).
