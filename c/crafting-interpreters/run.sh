#!/bin/bash
clang -std=c23 -O3 -Wall -Wextra -Wpedantic -Werror $1 -o tempout &&\
    ./tempout && rm tempout
