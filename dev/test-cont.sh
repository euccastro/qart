#!/bin/bash
# Test runner for continuation tests
# Run separately from main tests due to potential state corruption

cd "$(dirname "$0")/.."

echo "=== Running Continuation Tests ==="
echo

# First make sure it builds
make > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

# Run CC-SIZE tests
echo "Testing CC-SIZE..."
timeout 2 cat dev/test-cc-size.fth | ./out/qart
RESULT=$?

if [ $RESULT -eq 124 ]; then
    echo "ERROR: CC-SIZE tests timed out"
    exit 1
elif [ $RESULT -ne 0 ]; then
    echo "ERROR: CC-SIZE tests failed with exit code $RESULT"
    exit 1
fi

echo "CC-SIZE tests passed"

# Run ALLOT and CALL/CC tests
echo "Testing ALLOT and CALL/CC..."
timeout 2 cat dev/test-allot-clean.fth | ./out/qart
RESULT=$?

if [ $RESULT -eq 124 ]; then
    echo "ERROR: Tests timed out (possible infinite loop)"
    exit 1
elif [ $RESULT -ne 0 ]; then
    echo "ERROR: Tests failed with exit code $RESULT"
    exit 1
fi

echo "ALLOT and CALL/CC tests passed"
echo
echo "=== All Continuation Tests Passed ==="