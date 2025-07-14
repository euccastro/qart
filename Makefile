# Makefile for x86_64 assembly projects

AS = nasm
ASFLAGS = -f elf64
LD = ld
LDFLAGS = 

# Default target
all: hello_nasm step01_stack step02_push_pop step03_threaded_list step04_lit_primitive step05_next_mechanism step06_add_primitive

# Build hello world
hello_nasm: hello_nasm.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.1 - stack demo
step01_stack: step01_stack.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.2 - push/pop subroutines
step02_push_pop: step02_push_pop.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.3 - threaded list
step03_threaded_list: step03_threaded_list.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.4 - LIT primitive
step04_lit_primitive: step04_lit_primitive.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.5 - NEXT mechanism
step05_next_mechanism: step05_next_mechanism.o
	$(LD) $(LDFLAGS) $< -o $@

# Build step 0.6 - ADD primitive
step06_add_primitive: step06_add_primitive.o
	$(LD) $(LDFLAGS) $< -o $@

# Pattern rule for assembly files
%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f *.o hello_nasm step01_stack step02_push_pop step03_threaded_list step04_lit_primitive step05_next_mechanism step06_add_primitive

# Run the program (runs the latest step)
run: step06_add_primitive
	./step06_add_primitive

.PHONY: all clean run