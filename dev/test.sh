#!/bin/bash
# Run tests in normal mode (shows only FAIL)

DIR="$(dirname "$0")"
"$DIR/../out/qart" < "$DIR/test.fth"
