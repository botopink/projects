# template-runtime-as-bp-module — rewrite `wat_runtime.zig`'s prelude as a `.bp` module

**Slug**: template-runtime-as-bp-module
**Depends on**: `templates-decorators-botopink-native` F1–F6 (record types, optionals, strings, lists, try/catch — all in the wat backend, all shipped).
**Status**: pending (authored 2026-06-20; next session work)

## Motivation

Today `modules/compiler-core/src/comptime/runtime/wat_runtime.zig` ships the comptime prelude as a giant inline WAT string literal — ~500 LOC of Zig wrapping ~350 LOC of WAT inside `\\`-multiline strings. Eric's direction: rewrite this as a `.bp` source module compiled through our own wat backend.

**Why this matters**:

1. **Self-hosting / dogfooding.** Proves the wat backend can emit everything the comptime layer needs.
2. **F1–F5 features land for free.** Anon records, optionals, strings, lists, try/catch — all shipped in this task — become real features consumed by the prelude itself instead of just pinned in fixtures.
3. **Maintainable by `.bp` readers**, not just by people who can hand-roll WAT.
4. **Forward propagation**: any future wat codegen improvement (better struct layout, smaller alloc machinery, …) automatically improves the prelude with zero touch in this module.
5. **Testable as `.bp`**: `test "..."` blocks inside the prelude `.bp` exercise it the same way every other lib does.

## Approach (hybrid)

A pure-`.bp` prelude isn't viable — some primitives (WASI fd_write import, heap pointer global, error register global, `__bp_alloc` bump helper, `__emit_raw` raw fd_write call) are below the bp surface. So the architecture is:

```
prelude() :=
    raw infrastructure (Zig string, ~30 LOC of WAT):
        - import wasi_snapshot_preview1.fd_write
        - global $__bp_heap_ptr / $__bp_err
        - func $__bp_alloc
        - func $__emit_raw
    +
    compile(libs/std/src/template_runtime.bp) via wat codegen:
        - record types (Span, CustomNode, Capture, Decl)
        - constructor fns (__expr, __code, Span, CustomNode, __capture)
        - error fns (__failRaw, __compilerError)
        - capture methods (__capture__value/text/parts/source/context/lookup/bindings/build/custom/fail/failAt)
        - decl reflection (__decl__kind/name/fields/methods/returnType/annotations/fail/failAt)
        - outcome envelopes (__emit_outcome_code/capture/error using the existing F3 string concat machinery)
```

## DAG

```
F0  identify which prelude fns can become .bp (most), which stay raw WAT (alloc + emit_raw + fd_write)
F1  write libs/std/src/template_runtime.bp with the record types + constructor fns
F2  compile-time gate: invoke wat.codegenEmit on template_runtime.bp inside wat_runtime.prelude(),
    extract the function bodies only (drop the (module ...) wrapper), concat with the raw infrastructure
F3  cache process-lifetime so the compile only happens once per binary
F4  prove parity: byte-equal wat output vs the current hand-rolled prelude
F5  delete the hand-rolled prelude string from wat_runtime.zig (~400 LOC removed)
F6  add an inline test "..." in template_runtime.bp exercising each constructor at the bp level
```

## Bootstrap concern

`evaluateWat` (the F8/F9 dispatcher) calls `prelude()` to assemble the WAT module that runs the template body. With F0 done, `prelude()` itself depends on the wat backend — exactly the same backend the template body uses. **There is no circular dependency**: `prelude()` calls `codegenEmit` to compile a fixed `.bp` source it owns; the compiled bytes get cached on first call. Subsequent calls are O(1) memcpy.

If a future profile shows the cold-compile cost is high, the cache file can be promoted to a build-time precomputed asset (`zig build` step that compiles `template_runtime.bp` and embeds its WAT output as a `[]const u8` constant — same shape `vendor/wasm3/source/` ships today).

## Out-of-scope `#[@external]` primitives

The four below stay as raw WAT in `wat_runtime.zig` because they have no clean `.bp` representation:

- `$__bp_fd_write` — WASI host import, needs `(import "wasi_snapshot_preview1" "fd_write" ...)`.
- `$__bp_alloc(nbytes)` — bump heap, needs direct `global.get/set $__bp_heap_ptr` + `i32.add`.
- `$__emit_raw(ptr, len)` — direct `(call $__bp_fd_write ...)` with iovec layout at offset 200.
- `$__bp_err` global — directly mutated by `__failRaw` (which sets it then traps).

The `.bp` prelude calls these by name (the wat backend treats unbound names as imports the linker resolves). The `prelude()` Zig helper still emits them ahead of the compiled `.bp` output so resolution at wasm3 load time succeeds.

## Acceptance gate

- `wat_runtime.prelude(allocator)` returns byte-identical (modulo whitespace) WAT vs the current hand-rolled version.
- All existing tests in `wat_runtime.zig` still pass — `__emit_raw round-trips`, `__emit_outcome_code wraps`, the JSON-round-trip, descriptor JSON round-trip.
- A new test loads `libs/std/src/template_runtime.bp` directly and verifies each constructor produces a record with the expected slot layout.
- Removed LOC count: ≥ 400 from `wat_runtime.zig`. New LOC in `template_runtime.bp`: ~150 (the wat backend's compactness vs the verbose WAT we hand-rolled).

## Why this is `b` (not `a` in this session)

The refactor is non-trivial (~6-8h of focused work), touches both the wat backend and the wat_runtime, and has bootstrap subtleties. Splitting it from F1–F6 keeps the foundation work committed, tested, pushed, and reviewable on its own. This spec captures the direction so the next session opens with a clear plan.
