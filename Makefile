# Makefile for qart - x86_64 Forth implementation

AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

# Default target
all: qart

# Build qart
qart: qart.o
	$(LD) $(LDFLAGS) $< -o $@

# Pattern rule for assembly files
%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f *.o qart

# Run qart
run: qart
	./qart

.PHONY: all clean run