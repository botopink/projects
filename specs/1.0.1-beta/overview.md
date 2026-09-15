# Specs — 1.0.1-beta

Everything left open by [`1.0.0-beta`](../1.0.0-beta/overview.md) and by the step-1 `todo.md`.
Comptime eval on `erl` (decorators + templates), the `erl_ast` Erlang emitter, Zig-folded
comptime `val`s and the decorator regression tests are done and are not repeated here.

| # | Spec | Priority | What |
|---|------|----------|------|
| 01 | [`01-suite-clean.md`](./01-suite-clean.md) | critical | The 13 leaks in `executeErlang`, suite exit gate (0 failures, 0 leaks, no `.snap.md.new`, no orphan `beam.smp`), mutation check of the decorator regression tests. |
| 02 | [`02-type-system.md`](./02-type-system.md) | medium | Types as comptime values, `#[@code]` type lifting, std type functions in `.bp`, narrowing audit. |
| 03 | [`03-codegen-hardening.md`](./03-codegen-hardening.md) | medium | Empty/wrong RUN LOGs per backend (with the baseline bugs accepted in 1.0.0-beta), WAT execution, missing coverage, `persistent_erl` tests. |
| 04 | [`04-erlang-emitter-cleanup.md`](./04-erlang-emitter-cleanup.md) | low | Optional leftovers of the `Term`/`erl_ast` migration. |
| 05 | [`05-repo-hygiene.md`](./05-repo-hygiene.md) | low | Findings of the docs audit: orphan std files, broken scripts/manifests, stale comments, license. |

## Dependencies

```
01-suite-clean
  ├──► 03-codegen-hardening  (RUN LOG audit needs a leak-free suite; step 1 of 01 touches runtime.zig too)
  └──► 04-erlang-emitter-cleanup  (byte-identical snapshot gate needs a clean baseline)
02-type-system       — independent of 03/04/05
05-repo-hygiene      — independent; item 5.6 overlaps 03 step 2 (executeWat doc comment)
```

02 steps 2–5 and 02 Part B all touch `comptime/infer.zig`: do not run them in parallel branches.

## Branches

Each spec runs in its own worktree `.tasks/<name>` and branch — see
[`../../AGENTS.md`](../../AGENTS.md#worktrees).
