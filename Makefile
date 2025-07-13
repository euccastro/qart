# Makefile for x86_64 assembly projects

AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

# Default target
all: hello_nasm

# Build hello world
hello_nasm: hello_nasm.o
	$(LD) $(LDFLAGS) $< -o $@

# Pattern rule for assembly files
%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f *.o hello_nasm

# Run the program
run: hello_nasm
	./hello_nasm

.PHONY: all clean run