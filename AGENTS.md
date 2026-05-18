# AGENTS.md

This file provides guidance to AI agents when working with this repository.

## AGENTS index

- [`AGENTS.md`](AGENTS.md) (root)
- [`modules/AGENTS.md`](modules/AGENTS.md)
- [`modules/compiler-core/AGENTS.md`](modules/compiler-core/AGENTS.md)
- [`modules/compiler-core/src/AGENTS.md`](modules/compiler-core/src/AGENTS.md)
- [`modules/compiler-core/src/codegen/AGENTS.md`](modules/compiler-core/src/codegen/AGENTS.md)
- [`modules/compiler-core/src/comptime/AGENTS.md`](modules/compiler-core/src/comptime/AGENTS.md)
- [`modules/compiler-core/src/comptime/runtime/AGENTS.md`](modules/compiler-core/src/comptime/runtime/AGENTS.md)
- [`modules/compiler-core/src/format/AGENTS.md`](modules/compiler-core/src/format/AGENTS.md)
- [`modules/compiler-core/src/lexer/AGENTS.md`](modules/compiler-core/src/lexer/AGENTS.md)
- [`modules/compiler-core/src/parser/AGENTS.md`](modules/compiler-core/src/parser/AGENTS.md)
- [`modules/compiler-core/src/utils/AGENTS.md`](modules/compiler-core/src/utils/AGENTS.md)
- [`modules/stdlib/AGENTS.md`](modules/stdlib/AGENTS.md)

## Commands

Workspace commands (run from repository root):

```bash
zig build           # compile CLI + language server
zig build test      # run compiler-core + language-server tests
zig build run       # run the CLI entry point
```

Compiler-core focused commands (run from `modules/compiler-core/`):

```bash
zig build
zig build test
zig build test -- --test-filter "use decl"
```

## Repository architecture

- `modules/compiler-core/` — compiler library (lexer, parser, AST, type inference, comptime, codegen, formatter)
- `modules/compiler-cli/` — CLI executable
- `modules/language-server/` — LSP executable
- `modules/stdlib/` — standard library declarations

## Compiler pipeline

### Source text → typed output

```
modules/compiler-core/src/lexer.zig        Lexer.init(src) → scanAll(alloc) → []Token
modules/compiler-core/src/parser.zig       Parser.init(tokens) → parse(alloc) → ast.Program
modules/compiler-core/src/ast.zig          AST for untyped + typed phases
modules/compiler-core/src/comptime/        Hindley-Milner inference + comptime validation/evaluation
modules/compiler-core/src/format.zig       Wadler-Lindig formatter
modules/compiler-core/src/print.zig        rustc-style diagnostics renderer
```

### Typed output → code generation

```
modules/compiler-core/src/codegen.zig                  Public API (compile, codegenEmit, generate)
modules/compiler-core/src/codegen/config.zig           Target/runtime config
modules/compiler-core/src/codegen/moduleOutput.zig     Module input/output model
modules/compiler-core/src/codegen/commonJS.zig         CommonJS emitter
modules/compiler-core/src/codegen/erlang.zig           Erlang emitter
modules/compiler-core/src/codegen/runtime.zig          Runtime helpers for executing generated JS/Erlang in tests
modules/compiler-core/src/codegen/snapshot.zig         Snapshot test helpers
modules/compiler-core/src/comptime/runtime/node.zig    Node.js comptime runtime
modules/compiler-core/src/comptime/runtime/erlang.zig  Erlang comptime runtime
```

The codegen API is two-phase:

1. `compile(alloc, modules, io, config) -> ComptimeSession`
2. `codegenEmit(alloc, outputs, config) -> []ModuleOutput`

`generate(...)` is the convenience wrapper that runs both phases.

## AST model (current)

`ExprOf(phase)` is now categorized by expression families:

- `literal`, `identifier`
- `binaryOp`, `unaryOp`
- `jump` (`return`, `throw`, `try`, `break`, `yield`, `continue`)
- `branch` (`if`, `tryCatch`)
- `loop`
- `binding`, `call`, `function`, `collection`, `comptime_`

Legacy variants such as `controlFlow` and `staticCall` are no longer part of the active model.

## Snapshot testing

Snapshot files live under `modules/compiler-core/snapshots/`.

- Parser snapshots: `modules/compiler-core/snapshots/parser/*.snap.md`
- Codegen snapshots: `modules/compiler-core/snapshots/codegen/**/*`
- Comptime snapshots: `modules/compiler-core/snapshots/comptime/**/*`

On mismatch, tests emit `.snap.md.new` files that should be reviewed and either promoted or discarded.

## Recent commit context

Recent commits relevant to docs and implementation:

- `b86c5de` — refactor expression flow and refresh parser/comptime/codegen snapshots
- `e98f4f5` — ignore compiled `.a` artifacts (`format.o*.a`)
- `e61ba77` — snapshot refresh for Zig 0.16.0 API changes
- `9b93b5c` — remove `staticCall` and align compiler/LSP for Zig 0.16
- `787e5c0` — parser/codegen compatibility fixes for Zig 0.16

## Conventions

- All source, comments, commit messages, and documentation must be in **English**.
- `Parser.init(tokens)` does **not** store an allocator; parsing methods receive `alloc`.
- `TypeRef` must be used for type annotations (`named`, `array`, `tuple_`, `optional`, `errorUnion`, `function`).
- Record/struct/enum/interface shorthand declarations must map to the same AST nodes as long-form declarations.
- Record fields in source are `record { x: T }` (implicit `val`), and parser compatibility may accept both forms when needed.
- Formatter must remain round-trip stable: `format(parse(src))` should re-parse to an equivalent AST.
- Pipeline `|>` is left-associative and should keep stable formatting across parse/format cycles.
