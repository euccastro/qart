# Makefile for qart - x86_64 Forth implementation

AS = nasm
ASFLAGS = -f elf64 -Isrc/
LD = ld
LDFLAGS = 

# Source directory
SRCDIR = src
OUTDIR = out

# All source files
SRCS = qart.asm flow.asm stack.asm arithmetic.asm memory.asm io.asm dictionary.asm input.asm word.asm debug.asm thread.asm time.asm
OBJS = $(addprefix $(OUTDIR)/,$(SRCS:.asm=.o))

# Default target
all: $(OUTDIR)/qart

# Create output directory
$(OUTDIR):
	mkdir -p $(OUTDIR)

# Build qart
$(OUTDIR)/qart: $(OBJS) | $(OUTDIR)
	$(LD) $(LDFLAGS) $^ -o $@

# Pattern rule for assembly files
$(OUTDIR)/%.o: $(SRCDIR)/%.asm | $(OUTDIR)
	$(AS) $(ASFLAGS) $< -o $@

# Clean build artifacts
clean:
	rm -f $(OUTDIR)/*.o $(OUTDIR)/qart

# Run qart
run: $(OUTDIR)/qart
	$(OUTDIR)/qart

.PHONY: all clean run
