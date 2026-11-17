-module(actor_test).
-export([main/0, actor/0]).

main() ->
    spawn_actors(1000000),
    io:format("Spawned 1 million actors~n").

spawn_actors(0) -> ok;
spawn_actors(N) when N > 0 ->
    spawn(fun actor/0),
    spawn_actors(N - 1).

actor() ->
    receive
        stop -> ok;
        _ -> actor()
    end.
