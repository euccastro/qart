# Makefile for x86_64 assembly projects

AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

# Default target
all: hello_nasm step01_stack step02_push_pop

# Build hello world
hello_nasm: hello_nasm.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.1 - stack demo
step01_stack: step01_stack.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.2 - push/pop subroutines
step02_push_pop: step02_push_pop.o
	$(LD) $(LDFLAGS) $< -o $@

# Pattern rule for assembly files
%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f *.o hello_nasm step01_stack step02_push_pop

# Run the program (runs the latest step)
run: step02_push_pop
	./step02_push_pop

.PHONY: all clean run