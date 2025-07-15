# Makefile for qart - x86_64 Forth implementation

AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

# All source files
SRCS = qart.asm flow.asm stack.asm arithmetic.asm memory.asm io.asm dictionary.asm
OBJS = $(SRCS:.asm=.o)

# Default target
all: qart

# Build qart
qart: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

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