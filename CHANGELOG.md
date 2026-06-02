# Changelog

All notable changes to the botopink compiler workspace are documented in this file.

## Unreleased

### Added

- **`@Result` / `@Option` method API** (stdlib)
  - `@Result<R, E>`: `.map`, `.flatMap`, `.unwrapOr`, `.isOk`, `.isError`.
  - `@Option<T>` (the canonical spelling of `?T`): `.map`, `.flatMap`, `.unwrapOr`.
  - Resolved by type inference and lowered inline per backend: `commonJS` and
    `erlang` emit the full form (`Ok`/`Error` tag match, option presence check);
    `beam` and `wasm` emit a documented stub.
  - Documented in `modules/stdlib/src/builtins.d.bp`.
- **Method calls on expressions** — `CallExpr.receiver` is now an expression, so
  method chains (`a().map(f).unwrapOr(0)`) and zero-arg method calls (`r.isOk()`)
  parse and type-check.

## v0.0.13-beta (May 2026)

### Highlights

- **Expression-flow refactor across compiler-core** (`b86c5de`)
  - `ast.ExprOf(phase)` now uses categorized families:
    `literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `call`, `function`, `collection`, `comptime_`.
  - Parser, formatter, comptime transform/specialization, JS/Erlang runtimes, and LSP integration were updated to the new shape.
  - Legacy variants such as `controlFlow`/`staticCall` are no longer active in the main AST flow.
- **Snapshot baseline refresh** (`b86c5de`, `e61ba77`)
  - Parser, comptime, and codegen snapshots were regenerated to match Zig `0.16.0` behavior and the new AST shape.
  - Obsolete snapshot files were removed where test semantics changed.
- **Codegen/runtime cleanup**
  - Runtime execution helpers are now centralized under `modules/compiler-core/src/codegen/runtime.zig`.
  - Stale path `modules/compiler-core/src/codegen/d` was removed from tracked sources.

### Maintenance

- **Ignore generated static library artifacts** (`e98f4f5`)
  - Added ignore rule for `format.o*.a` to avoid polluting commits with local Zig artifacts.

### Compatibility context in this release line

- `787e5c0` — Zig `0.16.0` compatibility and parser consistency fixes.
- `9b93b5c` — removed `staticCall` and aligned compiler/LSP code paths for Zig `0.16`.

## v0.0.12-beta (April 2026)

- Added full `language-server` module with diagnostics, hover, definition, references, rename, signature help, inlay hints, and formatting.
- Standardized parser parameter typing around `TypeRef`.
- Unified workspace build flow for compiler CLI + language server.
- Improved comptime/LSP resilience for incomplete sources.

## v0.0.11-beta (April 2026)

- Consolidated allocator style to **never store, always pass** in parser/codegen APIs.
- Added Erlang code generation backend parity and snapshot coverage improvements.
- Added/expanded language features including pipeline (`|>`), anonymous `fn` expressions, and richer pattern matching snapshots.
