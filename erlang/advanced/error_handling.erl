-module(error_handling).
-export([main/0, safe_divide/2]).

safe_divide(_, 0) -> {error, division_by_zero};
safe_divide(A, B) -> {ok, A / B}.

main() ->
    %% Handling result tuples
    case safe_divide(10, 2) of
        {ok, Result1} -> io:format("10 / 2 = ~p~n", [Result1]);
        {error, Reason1} -> io:format("Error: ~p~n", [Reason1])
    end,

    case safe_divide(10, 0) of
        {ok, _} -> ok;
        {error, Reason2} -> io:format("Handled expected error: ~p~n", [Reason2])
    end,

    %% Using try...catch
    try
        throw(something_went_wrong)
    catch
        throw:CaughtReason -> io:format("Caught throw: ~p~n", [CaughtReason])
    end,


    try
        1 / 0
    catch
        error:badarith -> io:format("Caught arithmetic error~n")
    after
        io:format("Cleanup logic here...~n")
    end.
