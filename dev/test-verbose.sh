#!/bin/bash
# Run tests in verbose mode (shows both PASS and FAIL)

DIR="$(dirname "$0")"
echo "1 DEBUG!" | cat - "$DIR/test.fth" | "$DIR/../out/qart"
