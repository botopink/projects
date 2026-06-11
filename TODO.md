# TODO — effect-annotations  (core · Wave 2 of 3)

> Task branch `task/effect-annotations` · spec
> [`tasks/v0.beta.10/specs/effect-annotations.md`](tasks/v0.beta.10/specs/effect-annotations.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on:** nothing. **Coordination:** touches the 4 codegen emitters — one of
> the 3 codegen-emitter Wave-2 specs (with `stdlib-backends-parity`,
> `cross-module-codegen`); different region (function-keyword lowering), but
> sequence the merges. Syntax/marker change over a working effect system.

## F0 — parse the effect annotations
- [x] Recognize `#[@result]`/`#[@future]`/`#[@generator]`/`#[@iterator]`/
      `#[@asyncGenerator]`/`#[@context]` as builtin effect decorators on a `fn`.
      Replace `FnDecl.isStarFn: bool` with `FnDecl.effect: ?EffectKind`; the parser
      stops requiring the `*` prefix. (`ast.EffectKind` + `parser/decls.zig`; `*fn`
      kept as a deprecated alias via `EffectKind.fromStarReturn`.)

## F1 — effect ↔ return-type + body ops
- [x] Check the annotation against the return wrapper (`#[@future]`→`@Future<…>`,
      etc.; clear diagnostic on mismatch — `effectMatchesReturn`). Gate body ops by
      effect kind: `await` under future/asyncGenerator; `yield`/delegation under
      generator/iterator/asyncGenerator (`StarFnCtx.allowsYield`); `throw`/`try`
      under result (`env.throwContext`).

## F1b — annotation is implementation-only
- [x] `#[@<effect>]` marks an **implementation** (fn with body). Interface methods
      (`validateEffectAnnotations`) and bodyless `declare fn` (`inferFnDecl`) express
      the effect through the return **wrapper**, no annotation — using the annotation
      there is an error. Existing builtin interfaces stay annotation-free.

## F2 — codegen off the effect kind (no behaviour change)
- [x] Replaced `f.isStarFn` + `starFnKind(returnType)` (`commonJS.zig fnKeyword`)
      with `FnDecl.effect`. Exact lowering kept (future→async function, generator/
      iterator→function*, asyncGenerator→async function*, result/context→plain).
      Mirrored on erlang/beam/wasm. Byte-identical to `*fn` (proved by a test).

## F3 — register the annotations as builtins
- [x] Documented the effect annotations in `builtins.d.bp` (recognized as core
      builtins by the compiler; no `fn` decl, to avoid colliding with the `result`
      namespace). `@Future<T>` ≡ `@Future<T, E>` already works (one-arg form).

## F4 — migrate every `*fn` + deprecate the prefix
- [x] Migrated `libs/std` (`primitives.d.bp` `parse` → `#[@result]`), the gated
      `examples/jhonstart-app`, and the `libs/jhonstart` / docs comments. `*fn` kept
      working (deprecated alias) so the existing codegen snapshots stay green; no
      iterator-generator `*fn` exists in the tree to migrate.

## F5 — docs + tests
- [x] `docs.md` §Effects (model + per-effect body ops + codegen mapping); comptime
      + codegen AGENTS.md updated. Parser tests (`effect` kind), infer-error tests
      (mismatch / yield-in-future / annotation-on-declare / -interface), codegen
      snapshots (4 backends) + a byte-identical-to-`*fn` test.

## Done gate
- [x] Each annotation lowers to the right JS keyword (and erlang/beam/wasm parity);
      `#[@future]` body using `yield` errors; annotation/return mismatch errors;
      `#[@<effect>]` on an interface/bodyless decl errors.
- [x] Migrated `libs/std` + jhonstart + examples build + test green.
- [x] `zig build && zig build test` green.
