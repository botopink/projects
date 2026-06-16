# option-expect — `Option.expect<T>(default: T) -> T` for proven-in-bounds unwraps

**Slug**: option-expect
**Depends on**: nothing — single additive method on the existing `?T` surface.
**Files**: `libs/std/src/builtins.d.bp` (1 new method on `?T`),
  `comptime/infer.zig` (handler arm in the option-method dispatch),
  `comptime/transform.zig` (lowering — same shape as `unwrapOr`),
  `tests/comptime/option_expect.zig` (new — exact ordering + sentinel),
  `tests/codegen/option_expect.zig` (new — round-trip on commonJS +
  erlang).
**Touches docs**: `libs/std/AGENTS.md` (option method table — new row),
  `libs/std/src/builtins.d.bp` doc comments, `CHANGELOG.md`.
**Status**: pending

## Premise

`std-expansion-tail`'s F4.random.shuffle deferred because shuffling a
generic `Array<T>` needs to extract an element at a known-valid index
without a `match` ceremony. The current `?T` surface offers
`unwrapOr(default)` which forces every caller to supply a value of type
`T` — fine for concrete primitives, but for a generic shuffle/swap
implementation over `T` there is no natural default. Three landed
modules already work around this with sentinel values
(`xs.at(idx).unwrapOr("")` in `path.bp`/`random.bp`/`unicode.bp`), and
each call site documents the "we know this won't fire" intent inline.

`Option.expect<T>(default: T) -> T` formalises the pattern: identical
runtime semantics to `unwrapOr`, but the name signals to the reader
"the absent branch is unreachable; this default is the sentinel".
Adding it is one annotation row on `?T` in `builtins.d.bp`, one
handler arm in `inferBuiltinOptionMethod`, and one lowering line in
the option-method transform. The §A2 templates already wired for
`unwrapOr` reuse verbatim.

## Surface

```bp
//// On `?T` (option), declared in `builtins.d.bp`:
//
// Unwrap the value, falling back to `default` when absent. Identical
// runtime behaviour to `unwrapOr` — the name is the only difference.
// Use when you can prove the value is present (e.g. `xs.at(i)` after a
// bounds check) and want the reader to see the assertion intent.
default fn expect<T>(self: ?T, default: T) -> T
```

## Steps

- [ ] `libs/std/src/builtins.d.bp` — add the `expect<T>` row next to
      `unwrapOr<T>` in the `?T` section. The doc comment explicitly
      cites the "proven in bounds" use case so reviewers don't read it
      as a synonym to `unwrapOr` (the choice is intentional — see the
      "Why a synonym" note below).
- [ ] `comptime/infer.zig` — extend `inferBuiltinOptionMethod` (or
      whichever function carries the `unwrapOr` arm) to recognise
      `expect` as a method on `?T` with the same arity / typing as
      `unwrapOr`. Returns the inner type `T`.
- [ ] `comptime/transform.zig` — extend the option-method lowering to
      emit the same shape as `unwrapOr` for `expect` (no per-backend
      branch needed — every backend already handles `unwrapOr`).
- [ ] `tests/comptime/option_expect.zig` — new fixture: `val o: ?i32 =
      some(42); val v = o.expect(0)` returns 42; `val n: ?i32 = null;
      val v = n.expect(99)` returns 99 (semantically identical to
      `unwrapOr` — pin the contract).
- [ ] `tests/codegen/option_expect.zig` — round-trip on commonJS +
      erlang. Snapshots regenerate on first run, stay pinned.
- [ ] `libs/std/AGENTS.md` — extend the option-method table row to
      mention `expect`.
- [ ] `CHANGELOG.md` — `feat(std): Option.expect — proven-in-bounds
      unwrap surface` entry under "Added".

## Test scenarios

```
ok   option.expect on Some returns the inner value
ok   option.expect on None returns the default
ok   option.expect lowers to the same JS / Erlang shape as unwrapOr
green   xs.at(i).expect(sentinel) round-trips through the §A2 template path
```

## Why a synonym

The `expect` / `unwrapOr` distinction matches the Rust convention
(`Option::expect("msg")` panics with a message on None; `Option::unwrap_or(default)`
returns the default). botopink's `Option` runtime doesn't carry a panic
surface for `expect` (the spec deliberately keeps the `?T` shape
backend-portable; `@panic` is opt-in at the call site), so `expect`
takes a `default` argument identical to `unwrapOr` — what changes is
the name's documentation contract. Use `unwrapOr(default)` when the
default is a meaningful fallback; `expect(sentinel)` when the absent
branch is unreachable and the default is purely a type witness.

## Exit gate

- [ ] `zig build test` green; new fixtures pass on the first run after
      snapshots seed.
- [ ] `botopink-lib-test --lib std --target commonJS,erlang` green.
- [ ] `random.shuffle<T>` (`std-expansion-tail-followup` P17) ships
      with `expect` consuming the surface — pull this spec **before**
      P17.
- [ ] `libs/std/AGENTS.md` option-method table updated; CHANGELOG
      entry under "Added".
