# Specs — 1.0.1-beta

Everything left open by [`1.0.0-beta`](../1.0.0-beta/overview.md).
Comptime eval on `erl` (decorators + templates), the `erl_ast` Erlang emitter, Zig-folded
comptime `val`s and the decorator regression tests are done and are not repeated here.

| # | Spec | Priority | What |
|---|------|----------|------|
| 01 | [`01-suite-clean.md`](./01-suite-clean.md) | critical | The leaks in `codegen/runtime.zig` (13 warm, 19 cold), suite exit gate from a **cold** runtime cache (0 failures, 0 leaks, no `.snap.md.new`, no orphan `beam.smp`), mutation check of the decorator regression tests. |
| 02 | [`02-type-system.md`](./02-type-system.md) | medium | Checker correctness (C1–C13: `return`, `case`, patterns, methods, record update), types as comptime values, `#[@code]` type lifting, std type functions in `.bp`, narrowing audit. |
| 03 | [`03-codegen-hardening.md`](./03-codegen-hardening.md) | medium | Empty/wrong RUN LOGs per backend (with the baseline bugs accepted in 1.0.0-beta), WAT execution, missing coverage, `persistent_erl` tests. |
| 04 | [`04-erlang-emitter-cleanup.md`](./04-erlang-emitter-cleanup.md) | low | Optional leftovers of the `Term`/`erl_ast` migration. |
| 05 | [`05-repo-hygiene.md`](./05-repo-hygiene.md) | low | Findings of the docs audit and of the snapshot review that are not compiler bugs: orphan std files, broken scripts/manifests, dead test files, retired syntax, ignore rules, license. |
| 06 | [`06-snapshot-review.md`](./06-snapshot-review.md) | critical | Every snapshot reviewed against its test and re-checked at HEAD (evidence in `06-snapshot-review/`): harness defects H1–H10 that make the suite green on unchecked output (inverted BEAM check, `erlc` warnings dropped, failed compiles recorded as empty snapshots, only the first backend of a test compared, RUN LOGs that exist only in the local runtime cache), root causes per backend/checker/parser/LSP, fix plan. |

The suite is green (1572/1572) only with a warm local runtime cache; from a cold cache it is
1493/1572 with 19 leaks. Spec 06 step 0 is what makes a cold run meaningful, so it comes first.

## Dependencies

```
06 step 0 (harness H1–H10)  ⇄  01 step 1 (same runtime.zig lines — land as one change)
  ├──► 01 exit gate  (0 failures / 0 leaks from a cold runtime cache)
  │      └──► 04-erlang-emitter-cleanup  (byte-identical snapshot gate needs a clean baseline)
  ├──► 03-codegen-hardening  (RUN LOG audit needs H1/H2/H5 and a cold re-record)
  ├──► 02-type-system  (H3/H9: a snapshot test must fail when its program does not compile)
  └──► 06 steps 1-5 ──► feed 02 (checker) / 03 (codegen) / 05 (hygiene) with the findings
02-type-system       — independent of 03/04/05 once H3/H9 are in
05-repo-hygiene      — independent; 5.6/5.7 overlap 03 step 2 (WAT), 5.11 = 06 H7,
                       5.15 = 06 step 1.2, 5.12/5.13 = the parser findings 06 routes here
```

The 06 parse-error-location, lexer-line and LSP root causes have no owner spec yet: open one
(or extend 05) when step 3 reaches those reports.

02 Part 0, steps 2–5 and step 6 all touch `comptime/infer.zig`: do not run them in parallel
branches (C4 and step 7 can run beside them).

## Branches

Each spec runs in its own worktree `.tasks/<name>` and branch — see
[`../../AGENTS.md`](../../AGENTS.md#worktrees).
