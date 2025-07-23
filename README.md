# qart

Playing with x86_64 assembly, FORTH, and Claude.

Currently got a FORTH interpreter/compiler working, which can compile colon definitions.

## Requirements

linux, build-tools, nasm.

## Build

`make run` should get you into a REPL.  The `qart` executable can also take FORTH code from stdin.

See `test.fth` for what is currently supported.

## More

See CLAUDE.md for more extensive (and probably more up-to-date) status, roadmap,
and other info to get you acquainted with this.
