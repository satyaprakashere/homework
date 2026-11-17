-module(list_processing).

-export([main/0]).

main() ->
    Numbers = [1, 2, 3, 4, 5],

    %% Using lists module
    Squared   = lists:map(fun(X) -> X * X end, Numbers),
    Evens = lists:filter(fun(X) -> X rem 2 == 0 end, Numbers),
    Sum = lists:foldl(fun(X, Acc) -> X + Acc end, 0, Numbers),

    %% Custom map implementation
    MySquared = my_map(fun(X) -> X * X end, Numbers),

    io:format("Numbers: ~p~n", [Numbers]),
    io:format("Squared: ~p~n", [Squared]),
    io:format("Evens: ~p~n", [Evens]),
    io:format("Sum: ~p~n", [Sum]),
    io:format("MySquared: ~p~n", [MySquared]).

my_map(_, []) ->
    [];
my_map(F, [H | T]) ->
    [F(H) | my_map(F, T)].
