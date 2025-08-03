#!/bin/bash
# Master test runner - runs all test suites

cd "$(dirname "$0")/.."

echo "=== Running All Test Suites ==="
echo

# Run main tests
echo ">>> Main Tests"
./dev/test.sh
if [ $? -ne 0 ]; then
    echo "Main tests failed!"
    exit 1
fi
echo

# Run thread tests  
echo ">>> Thread Tests"
./dev/test-thread.sh
if [ $? -ne 0 ]; then
    echo "Thread tests failed!"
    exit 1
fi
echo

# Run continuation tests
echo ">>> Continuation Tests"
./dev/test-cont.sh
if [ $? -ne 0 ]; then
    echo "Continuation tests failed!"
    exit 1
fi
echo

echo "=== All Test Suites Passed Successfully ==="