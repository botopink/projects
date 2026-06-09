# TODO — jhonstart-language-gaps

> Live checklist for branch `task/jhonstart-language-gaps` (worktree
> `.tasks/jhonstart-language-gaps/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/jhonstart-language-gaps.md`](tasks/v0.beta.6/specs/jhonstart-language-gaps.md)

> **Goal**: four *language* gaps surfaced building `libs/jhonstart` — making
> records + arrays ergonomic enough for a component/hook API. Pure language
> features; files: `parser*.zig`, `comptime/*`, `codegen/*`.

## F0 — G1 fn-typed record fields
- [x] parse + infer a record field typed as a function (`set: fn(next: T)`);
      codegen stores it as a closure value. (`get`/`set` are now soft keywords,
      valid as field/member names — the `{value, set}` hook shape.)

## F1 — G2 anonymous record types
- [x] anonymous record *type* syntax usable as annotation / return type
      (`-> { value: T, set: fn(T) }`) — `TypeRef.record_type` → `Type.record`

## F2 — G3 array-as-return parsing
- [x] `fn(...) -> T[]` (and nested `?T[]`, `T[][]`) parse + infer

## F3 — G4 Children coercion
- [x] `Element` → one-element list and `string` → text-node coercion into a
      `Children`-typed parameter (what `div([a, b])` needs); array passes through

## Notes
- All four gaps closed; spec Test scenarios live in
  `modules/compiler-core/src/comptime/tests/jhonstart.zig` (+ codegen smoke
  tests in `codegen/tests/js_aggregates.zig`).
- jhonstart F4–F5 (SSR/loaders) stay gated on the async specs in
  `tasks/v0.beta.1/`, not here.
