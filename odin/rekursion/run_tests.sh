#!/bin/bash
<<<<<<< HEAD
odin run src/ -define:ODIN_TEST=true # > output.txt 2>&1
=======

# Run tests and capture output
output=$(odin test src -out:out/rekursion_test 2>&1)

# Check if the test passed
if echo "$output" | grep -q "1 test passed"; then
    echo "All tests passed!"
else
    echo "Tests failed. Output:"
    echo "$output"
fi
>>>>>>> 92e2e66 ([update] mac mini update from feb 2026)
