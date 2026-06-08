# TODO — jhonstart-language-gaps

> Live checklist for branch `task/jhonstart-language-gaps` (worktree
> `.tasks/jhonstart-language-gaps/`).
> Spec (intent, immutable): [`tasks/v0.beta.6/specs/jhonstart-language-gaps.md`](tasks/v0.beta.6/specs/jhonstart-language-gaps.md)

> **Goal**: four *language* gaps surfaced building `libs/jhonstart` — making
> records + arrays ergonomic enough for a component/hook API. Pure language
> features; files: `parser*.zig`, `comptime/*`, `codegen/*`.

## F0 — G1 fn-typed record fields
- [ ] parse + infer a record field typed as a function (`set: fn(next: T)`);
      codegen stores it as a closure value

## F1 — G2 anonymous record types
- [ ] anonymous record *type* syntax usable as annotation / return type
      (`-> { value: T, set: fn(T) }`)

## F2 — G3 array-as-return parsing
- [ ] `fn(...) -> T[]` (and nested `?T[]`, `T[][]`) parse + infer

## F3 — G4 Children coercion
- [ ] `Element` → `[Element]` and `string` → text-node coercion into a
      `Children`-typed parameter (what `div { … }` needs)

## Notes
- Each gap is independently shippable — split further if parallelism helps.
- jhonstart F4–F5 (SSR/loaders) stay gated on the async specs in
  `tasks/v0.beta.1/`, not here.
