#!/bin/bash

# Run tests and capture output
output=$(cat tests/tests.scm | ./out/rekursion)

# Check if the test passed
if echo "$output" | grep -q "1 test passed"; then
    echo "All tests passed!"
else
    echo "Tests failed. Output:"
    echo "$output"
fi
