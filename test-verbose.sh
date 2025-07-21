#!/bin/bash
# Run tests in verbose mode (shows both PASS and FAIL)
# Usage: ./test-verbose.sh [test-file]
# Default: test.fth

TEST_FILE="${1:-test.fth}"
echo "1 FLAGS !" | cat - "$TEST_FILE" | ./qart
