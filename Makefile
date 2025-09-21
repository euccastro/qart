# Makefile for qart - x86_64 Forth implementation

AS = nasm
ASFLAGS = -f elf64 -Isrc/
LD = ld
LDFLAGS = --dynamic-linker=/lib64/ld-linux-x86-64.so.2

# SDL3 configuration
SDL3_DIR = third_party/SDL-release-3.2.22
SDL3_BUILD_DIR = $(SDL3_DIR)/build
SDL3_LIB = $(SDL3_BUILD_DIR)/libSDL3.a
SDL3_LDLIBS = -lm -ldl -lpthread -lrt -lc

# Source directory
SRCDIR = src
OUTDIR = out

# All source files
SRCS = qart.asm flow.asm stack.asm arithmetic.asm memory.asm io.asm dictionary.asm input_buffer.asm debug.asm thread.asm time.asm sdl.asm
OBJS = $(addprefix $(OUTDIR)/,$(SRCS:.asm=.o))

# Default target
all: $(OUTDIR)/qart

# Create output directory
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Build qart with SDL3 static linking
$(OUTDIR)/qart: $(OBJS) $(SDL3_LIB) | $(OUTDIR)
	$(LD) $(LDFLAGS) $^ $(SDL3_LDLIBS) -o $@

# Pattern rule for assembly files
$(OUTDIR)/%.o: $(SRCDIR)/%.asm | $(OUTDIR)
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f $(OUTDIR)/*.o $(OUTDIR)/qart

# Run qart
run: $(OUTDIR)/qart
	$(OUTDIR)/qart

# Run tests
test: $(OUTDIR)/qart
	dev/test.sh

# Debug build with symbols
debug: clean
	$(MAKE) ASFLAGS="$(ASFLAGS) -g -F dwarf" $(OUTDIR)/qart
	@echo "Debug build complete. Run: gdb $(OUTDIR)/qart"

.PHONY: all clean run test debug
