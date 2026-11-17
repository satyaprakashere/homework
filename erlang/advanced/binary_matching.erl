-module(binary_matching).

-export([main/0, parse_rgb/1]).

%% Pattern matching on binary data
parse_rgb(<<R:8, G:8, B:8>>) ->
    {rgb, R, G, B};
parse_rgb(_) ->
    {error, invalid_format}.

main() ->
    %% Creating binaries
    Bin = <<1, 2, 3>>,
    io:format("Binary: ~p~n", [Bin]),

    %% Parsing RGB
    RGB = <<255, 128, 0>>,
    case parse_rgb(RGB) of
        {rgb, R, G, B} ->
            io:format("Red: ~p, Green: ~p, Blue: ~p~n", [R, G, B]);
        Error ->
            io:format("Error: ~p~n", [Error])
    end,

    %% Bit-level matching
    <<Flags:4, Rest:4>> = <<2#10100101>>,
    io:format("Flags: ~.2B, Rest: ~.2B~n", [Flags, Rest]).
