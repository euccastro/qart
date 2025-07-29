#!/bin/bash
# Build threading examples

echo "Building thread-example..."
nasm -f elf64 thread-example.asm -o thread-example.o
ld thread-example.o -o thread-example

echo "Building thread-minimal..."
nasm -f elf64 thread-minimal.asm -o thread-minimal.o
ld thread-minimal.o -o thread-minimal

echo "Done. Run with:"
echo "  ./thread-example"
echo "  ./thread-minimal"