#!/bin/bash
# Build threading examples

DIR="$(dirname "$0")"
SRCDIR="$DIR/../src/thread"
OUTDIR="$DIR/../out"

# Create output directory if it doesn't exist
mkdir -p "$OUTDIR"

# Build all thread examples
for asm_file in "$SRCDIR"/*.asm; do
    if [ -f "$asm_file" ]; then
        base=$(basename "$asm_file" .asm)
        echo "Building $base..."
        nasm -f elf64 "$asm_file" -o "$OUTDIR/$base.o"
        ld "$OUTDIR/$base.o" -o "$OUTDIR/$base"
        rm "$OUTDIR/$base.o"  # Clean up object file
    fi
done

echo "Done. Thread examples built in $OUTDIR/"