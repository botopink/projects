# botopink/modules

## AGENTS links

- [Root AGENTS](../AGENTS.md)
- [Compiler-core AGENTS](compiler-core/AGENTS.md)
- [Stdlib AGENTS](stdlib/AGENTS.md)

## Directory Structure

- `core/` — Zig library: lexer, parser, type inference, comptime evaluation, codegen (CommonJS + Erlang), formatter
- `stdlib/` — Standard library declarations (`.bp` source files + prelude)

The codegen pipeline lives entirely in `core/`. There is no separate Node.js or
Wasm module — JavaScript and Erlang output are generated natively in Zig.

## Conventions

See the root `../AGENTS.md` for core architecture and testing guidelines.
