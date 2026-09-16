# Specs — 1.0.2-beta

What [`1.0.1-beta`](../1.0.1-beta/overview.md) left open, plus the library break it uncovered.
1.0.1-beta made the suite tell the truth (a run is decided by the process exit status, a program
that does not compile fails its test, every backend is compared) and gave each backend a code
model with a single emitter. This milestone spends that: the defects the suite now shows are
fixed, and the gate is widened to the libraries.

| # | Spec | Priority | What |
|---|------|----------|------|
| 01 | [`01-comptime-untyped-dispatch.md`](./01-comptime-untyped-dispatch.md) | critical | A template body calling a primitive `default fn` produces calls to undefined functions, so every library with a template is uncompilable; `botopink test` hides the diagnostic; `zig build test-libs` is in no gate. |
| 02 | [`02-type-system.md`](./02-type-system.md) | high | Checker correctness (`return` never unified with the declared return type, `case` typed as a fresh variable, swapped expected/found, type guards, the type builtins, permissive method/field checks), types as comptime values, narrowing. |
| 03 | [`03-codegen-hardening.md`](./03-codegen-hardening.md) | high | The lowerings the backends still miss (beam `declare fn` externals, unresolved method calls, string `+`, generators; wasm lambdas/loops/`case` payloads), WAT execution, missing coverage, `persistent_erl` tests. |
| 04 | [`04-emitter-centralization.md`](./04-emitter-centralization.md) | medium | The bridges that pin illegal shapes the lowering still emits (JS-1…JS-6, the erlang `raw` bug rows, the wat extern gap) — each one a commit that deletes its build sites. |
| 05 | [`05-repo-hygiene.md`](./05-repo-hygiene.md) | low | Orphan std files, manifests, hooks, `wasm3` leftovers, CI comments, license, and the rest of the audit. |
| 06 | [`06-snapshot-review.md`](./06-snapshot-review.md) | medium | The review's residual rows per report, the tracing/worksheet tooling, and the 4 byte-identical comptime copies per slug. |
| 07 | [`07-suite-and-harness.md`](./07-suite-and-harness.md) | low | The one thing spec 01 of 1.0.1-beta left: the decorator regression tests were never mutation-checked. |
| 08 | [`08-module-health.md`](./08-module-health.md) | critical | Four of six libraries cannot compile, three CLI commands report success on failure, and the gate never compiles a `.bp` library. |

## Waves

Each wave runs as one worktree per row under `.tasks/<name>`, with a `todo.md` carrying the
row's steps, the owned and forbidden files, and the exit gate. A wave's rows are file-disjoint
**and snapshot-disjoint** — that is what lets them run at the same time. A row lands by: merge
into `feat`, suite green in the main checkout, push, submodule bump in the meta repo, then the
worktree and branch are deleted.

### Wave 0 — foundation (blocking, run alone)

Everything downstream depends on these, and they regenerate snapshots across all four targets, so
nothing else may run beside them. A health check of the workspace found four of six libraries
uncompilable on **one** shared defect — the untyped comptime path — so that is the first row.

| Row | Owns | Closes |
|---|---|---|
| comptime dispatch | `codegen/erlang.zig` (the `untyped` path), `comptime/**` | spec 01 step 1 + spec 08 steps 1–2: a primitive method in a template **or decorator** body, including a mutation (`push`) inside a closure |
| CLI + gate | `modules/compiler-cli/**`, `build.zig`, `.github/workflows/**` | spec 01 steps 2–3 + spec 08 steps 4–5: commands that report success on failure, and a gate that compiles the libraries |
| std surface | `libs/std/**` | spec 08 step 6 + spec 03's std rows: the unshipped `gleam_stdlib.mjs`, `string:suffix/2` (not an OTP function), `slice` arity, the three modules no `mod` tree reaches |

**Gate for all three:** `zig build test && zig build test-libs` green, and `botopink test` passing
in every checked-out sibling library.

### Wave 1 — backend lowerings (parallel, 3 rows)

| Row | Owns | Closes |
|---|---|---|
| beam | `codegen/beam_asm.zig`, `codegen/beam/beam_emitter.zig`, `snapshots/codegen/beam/` | the 11 wrong fixtures + the 2 latent register bugs (spec 03) |
| erlang | `codegen/erlang.zig`, `codegen/beam/erl_ast.zig`, `codegen/beam/erl_emitter.zig`, `snapshots/codegen/erlang/` | the erlang residuals + the `raw` rows that are output bugs (specs 03/04) |
| wasm | `codegen/wat.zig`, `codegen/wat/**`, `snapshots/codegen/wasm/` | lambdas as values, loop accumulation, `case` on variant payloads, `f64` aggregate precision, array methods, host externals; then the `executeWat` decision (spec 03 step 2) |

### Wave 2 — checker (alone)

`comptime/infer.zig` decides the typed AST every backend consumes, so its rows change comptime
snapshots and can move codegen output. One worktree, spec 02 Part 0 first (the correctness rows),
then Parts A and B.

### Wave 3 — emitter bridges (parallel, 2 rows)

Each bridge is one commit that deletes its build sites and changes snapshots, so the rows are
split by backend and never share a snapshot directory.

| Row | Owns | Closes |
|---|---|---|
| js bridges | `codegen/commonJS.zig`, `codegen/typescript.zig`, `codegen/js/**`, `snapshots/codegen/commonJS/` | JS-1…JS-6 |
| erlang/wat bridges | `codegen/erlang.zig`, `codegen/wat/**` | the remaining `raw` rows, `Module.externs` |

### Wave 4 — review residuals, hygiene and the library repos (parallel, 4 rows)

| Row | Owns | Closes |
|---|---|---|
| review tooling + residuals | `utils/snap.zig`, `scripts/snap_audit.sh`, the test sources named in the reports | spec 06 |
| comptime copy dedup | `comptime/snapshot.zig`, `comptime/tests/helpers.zig`, `snapshots/comptime/**` | spec 06 step 4 |
| hygiene | `build.zig`, `scripts/**`, `.github/**`, `libs/std/botopink.json`, docs | spec 05 · spec 07 |
| library repos | `repository/{rakun,erika,emilia,vscode-extension}` (one commit per repo) | spec 08 step 7: rakun's missing `server` dependency, erika's stale docs, emilia's missing hook/CI, the extension's retired snippets |

## Dependencies

```
wave 0 (comptime dispatch · CLI + gate · std surface)
  ├──► wave 1 (beam · erlang · wasm)   — the std rows unblock several fixtures
  ├──► wave 2 (checker)                — trailing default params (spec 08 step 3) belongs here
  │      └──► wave 3 (emitter bridges) — a bridge deletion changes snapshots the checker moves
  └──► wave 4 (review residuals · hygiene · library repos)
```

Wave 0 first is not a preference: today the gate cannot see a broken library, and four of them are
broken, so any backend fix in wave 1 would be verified with the libraries' eyes closed.

## Rules carried from 1.0.1-beta

- **A backend builds a model, an emitter renders it.** Hand-written target text is not
  acceptable; when the model cannot express a construct, extend the model. `raw`-style nodes are
  for genuine host text only, and every remaining one is named in spec 04.
- **The gate is a cold runtime cache.** `.botopinkbuild/runtime-cache` is deleted before the run
  that decides a merge, otherwise a stale entry can hide an unexecuted backend.
- **A snapshot is evidence, not a baseline.** Re-record only a value you verified by running the
  program; a fixture that pins known-wrong output says so in the test.

## Branches

Each row runs in its own worktree `.tasks/<name>` and branch — see
[`../../AGENTS.md`](../../AGENTS.md#worktrees).
