-module(concurrency).
-export([main/0, worker/0]).

worker() ->
    receive
        {greet, Name} ->
            io:format("Hello, ~s from Erlang process!~n", [Name]),
            worker();
        stop ->
            ok
    end.

main() ->
    io:format("~n--- 1. Erlang Concurrency Demo ---~n"),
    Pid = spawn(fun worker/0),
    Pid ! {greet, "world"},
    Pid ! stop.
