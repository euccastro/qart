#!/bin/bash
# Run tests in normal mode (shows only FAIL)

echo "=== Running test.fth ==="
./qart < test.fth
echo
echo "=== Running store-test.fth ==="
./qart < store-test.fth
