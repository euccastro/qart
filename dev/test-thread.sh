#!/bin/bash
# Run threading tests

DIR="$(dirname "$0")"
"$DIR/../out/qart" < "$DIR/test-thread.fth"