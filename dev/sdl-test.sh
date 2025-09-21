#!/bin/bash
# Run SDL tests with proper setup (constants + test file)

set -e

TEST_FILE="$(dirname $0)/test/manual/sdl.fth"

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
    echo "Error: Test file '$TEST_FILE' not found"
    exit 1
fi

# Run with SDL constants + test file (with whitespace separator)
echo "Running SDL test: $TEST_FILE"
echo
cat src/sdl.fth <(echo " ") "$TEST_FILE" | dev/qi
