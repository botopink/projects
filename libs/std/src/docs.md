# std/src — registry & per-file roles

> Path: `libs/std/src/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)
> Parent: [`../docs.md`](../docs.md)

Single registry directory holding the `.bp`/`.d.bp` sources (no Zig). The
loader `modules/compiler-core/src/comptime/stdlib/prelude.zig` exposes every
`.bp` file as a compile-time string consumed by `compiler-core`'s type
inference. Adding a new stdlib module = drop a `.bp` here + one line in the
root `build.zig` (`std_bp_files`) + one line in `prelude.zig`.

## Tree

```text
src/
├── primitives.d.bp      ← numeric + bool interfaces
├── array.d.bp           ← generic Array<T> interface
├── string.d.bp          ← String interface methods
└── builtins.d.bp        ← @typeOf / @sizeOf / @panic / @typeName / …
```

## `prelude.zig` shape (in compiler-core)

```zig
// modules/compiler-core/src/comptime/stdlib/prelude.zig
pub const primitives = @embedFile("primitives.d.bp");
pub const array      = @embedFile("array.d.bp");
pub const string     = @embedFile("string.d.bp");
```

One `pub const` per `.bp`. Each name resolves through an anonymous import
declared in the root `build.zig` (`std_bp_files` → `addAnonymousImport`),
because the `.bp` sources live outside the `std_prelude` module root.

## Per-file roles

| File | What it declares |
|---|---|
| `primitives.d.bp` | `interface I32 { … }`, `U32`, `I64`, `U64`, `F32`, `F64`, `Bool`. Numeric methods: `to_string`, `abs`, `min`, `max`, `as<T>`. Bool methods: `to_string`. |
| `array.d.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.d.bp` | `interface String` — `len`, `split`, `to_upper`/`to_lower`, `contains`, `starts_with`, `ends_with`, `trim`/`trim_left`/`trim_right`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `builtins.d.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`), and the `@Result` enum + the `@Result`/`@Option` method API docs (`map`/`flatMap`/`unwrapOr`/`isOk`/`isError`). |

## `@Result` / `@Option` methods

`@Result<R, E>` and `@Option<T>` (the canonical spelling of `?T`) expose
`.map` / `.flatMap` / `.unwrapOr` (plus `.isOk` / `.isError` for Result). Unlike
the other stdlib signatures, these are **not** type-checked from a declaration —
they are special-cased in inference (`comptime/infer.zig`, `inferResultOptionMethod`)
and lowered by the AST transform into `__bp_<domain>_<op>(...)` builtin calls
that each codegen backend emits inline. `builtins.d.bp` documents the API in a
comment block (bodyless enum methods do not parse, so it cannot be a real
declaration). See the language reference `Result & Option methods` section.

## Declarative style — no bodies

```text
// ✅ valid stdlib declaration
interface String {
    fn len(): i32,
    fn to_upper(): string,
}

// ❌ stdlib files must not contain method bodies
interface String {
    fn len(): i32 = self.bytes.length()    // ← no
}
```

The type checker consumes the signatures; the actual implementations come
from each codegen target. JS uses host `String.prototype`; Erlang uses
binaries + `string` module functions.

## Adding a stdlib module — step-by-step

1. Create `src/<name>.bp` with `interface <Name> { … }` declarations.
2. Add `"<name>.bp"` to `std_bp_files` in the root `build.zig`.
3. Add `pub const <name> = @embedFile("<name>.bp");` to
   `modules/compiler-core/src/comptime/stdlib/prelude.zig`.
4. Run `zig build test` from `modules/compiler-core/` — expect snapshot
   churn under `snapshots/comptime/` (the type env now contains a new
   binding).
5. Promote the `.snap.md.new` files after reviewing the diffs.
6. If the new module is user-facing, mention it in the language
   reference [`../../../docs.md`](../../../docs.md).

## Conventions

- Keep declarations stable and additive — every rename forces snapshot
  churn across every codegen/comptime suite.
- Interfaces must stay declarative (no method bodies) — they are consumed
  by the type checker, not codegen.
- Generic parameters use `<T>`, `<K, V>` — the type checker handles
  instantiation per call site.

## See also

- Stdlib usage in user code → [`./examples.md`](examples.md).
- Wider stdlib design → [`../docs.md`](../docs.md).
- Type-env wiring → [`../../../modules/compiler-core/src/comptime/docs.md`](../../../modules/compiler-core/src/comptime/docs.md).
