#!/bin/bash
# Test runner - runs all .fth test files in dev/test directory

cd "$(dirname "$0")/.."

echo "=== Running All Tests ==="
echo

# Run each .fth file in dev/test directory with stdlib loaded
for test_file in dev/test/*.fth; do
    if [ -f "$test_file" ]; then
        echo ">>> Running $(basename "$test_file")"
        dev/qi "$test_file"
        if [ $? -ne 0 ]; then
            echo "Test failed: $(basename "$test_file")"
            exit 1
        fi
        echo
    fi
done

echo "Tests done."