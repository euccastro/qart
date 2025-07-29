#!/bin/bash
# Run tests in verbose mode (shows both PASS and FAIL)
# Usage: ./test-verbose.sh [test-file]
# Default: test.fth


echo "1 FLAGS !" | cat - test.fth | ./qart
