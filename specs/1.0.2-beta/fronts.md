# Fronts — what can run at the same time

The fronts say *what* to fix; this says *who may touch what, when*. A front is one worktree
(`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts may run at the same time only
when they share **no source file and no snapshot directory** — a shared snapshot directory is the
usual trap, because a codegen change re-records the whole directory and two fronts then fight over
the same 278 files.

Paths are relative to `repository/botopink-lang/` unless a row says otherwise.

## Ownership

| Front | Source it owns | Snapshots it owns |
|---|---|---|
| **F1** [`01-comptime-dispatch`](./01-comptime-dispatch/README.md) | `codegen/erlang.zig` (the `untyped` path), `comptime/template_eval.zig`, `comptime/decorator_eval.zig` | `snapshots/comptime/**` (1009) |
| **F2** [`02-cli-gate`](./02-cli-gate/README.md) | `modules/compiler-cli/**`, `build.zig` (steps), `.github/workflows/**`, `scripts/**` **except** `scripts/snap_audit.sh` | — |
| **F3** [`03-std-surface`](./03-std-surface/README.md) | `libs/std/**` (including `libs/std/botopink.json`) | — (but re-records **every** codegen directory) |
| **F4** [`04-beam`](./04-beam/README.md) | `codegen/beam_asm.zig`, `codegen/beam/beam_emitter.zig` | `snapshots/codegen/beam/` (278) |
| **F5** [`05-erlang`](./05-erlang/README.md) | `codegen/erlang.zig` (the typed path), `codegen/beam/erl_ast.zig`, `codegen/beam/erl_emitter.zig` | `snapshots/codegen/erlang/` (279) |
| **F6** [`06-wasm`](./06-wasm/README.md) | `codegen/wat.zig`, `codegen/wat/**` | `snapshots/codegen/wasm/` (278) |
| **F7** [`07-checker`](./07-checker/README.md) | `comptime/infer.zig`, `comptime/types.zig`, `comptime/env.zig`, `comptime/transform.zig`, `comptime/unify.zig`, `parser/exprs.zig` (the grammar gaps) | `snapshots/comptime/**` + it can move **all four** codegen directories |
| **F8** [`08-js-bridges`](./08-js-bridges/README.md) | `codegen/commonJS.zig`, `codegen/typescript.zig`, `codegen/js/**` | `snapshots/codegen/commonJS/` (279) |
| **F9** [`09-review-tooling`](./09-review-tooling/README.md) | `utils/snap.zig`, `scripts/snap_audit.sh`, `codegen/tests/**`, `comptime/tests/**`, `parser/tests/**`, `modules/language-server/src/tests/**` | — (it changes *which* tests run, not their output) |
| **F10** [`10-comptime-dedup`](./10-comptime-dedup/README.md) | `comptime/snapshot.zig`, `comptime/tests/helpers.zig` | `snapshots/comptime/**` (deletes 3 of 4 copies) |
| **F11** [`11-hygiene`](./11-hygiene/README.md) | `comptime/runtime/persistent_erl.zig` (the frame protocol), `examples/**`, prose: `AGENTS.md`/`README.md`/doc comments | — |
| **F12** [`12-library-repos`](./12-library-repos/README.md) | `repository/{rakun,erika,emilia,jhonstart,onze,vscode-extension}` (one commit per repo), `modules/bpmp/**` | — |

### What the ownership table had to settle

The first cut of this table was checked against the fronts' own analysis, and five things did not
hold:

- **The two-parameter `loop` that loses its accumulator** (erika, `codegen/erlang.zig`, both the
  typed and the comptime path) was claimed by no front. **F5** owns it; F1 inherits the fix
  because both paths share the lowering.
- **Trailing default parameters** are analysed in F1 (`01-comptime-dispatch/trailing-defaults.md`)
  but the fix is `comptime/infer.zig`'s arity checks — **F7's** file. F7 executes it; F1's document
  is the evidence.
- **`scripts/snap_audit.sh`** was claimed by both F2 (`scripts/**`) and F9. It is F9's.
- **`libs/std/botopink.json`** was claimed by both F3 and F11. It is F3's; F11 only reports on it.
- **`modules/bpmp/**`**, `comptime/runtime/persistent_erl.zig` and `modules/language-server/src/tests/**`
  had no owner. They are F12's, F11's and F9's respectively. The language server's *source* still
  has none: its one open finding (`completion_decorator_record`) is a checker defect, so it lands
  with F7.

## Conflict matrix

Read it as "may these two run at the same time?".

|  | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **F1** | — | yes | no¹ | yes | **no²** | yes | **no³** | yes | no⁴ | **no³** | after⁵ | yes |
| **F2** | yes | — | yes | yes | yes | yes | yes | yes | yes | yes | after⁵ | yes |
| **F3** | no¹ | yes | — | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ | no¹ | after⁵ | yes |
| **F4** | yes | yes | no¹ | — | yes | yes | no³ | yes | no⁴ | yes | after⁵ | yes |
| **F5** | **no²** | yes | no¹ | yes | — | yes | no³ | yes | no⁴ | yes | after⁵ | yes |
| **F6** | yes | yes | no¹ | yes | yes | — | no³ | yes | no⁴ | yes | after⁵ | yes |
| **F7** | **no³** | yes | no¹ | no³ | no³ | no³ | — | no³ | no⁴ | no³ | after⁵ | no⁶ |
| **F8** | yes | yes | no¹ | yes | yes | yes | no³ | — | no⁴ | yes | after⁵ | yes |
| **F9** | no⁴ | yes | no¹ | no⁴ | no⁴ | no⁴ | no⁴ | no⁴ | — | no⁴ | after⁵ | yes |
| **F10** | **no³** | yes | no¹ | yes | yes | yes | no³ | yes | no⁴ | — | after⁵ | yes |
| **F11** | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | after⁵ | — | yes |
| **F12** | yes | yes | yes | yes | yes | yes | no⁶ | yes | yes | yes | yes | — |

1. **F3 changes every backend's output.** `libs/std` is embedded in the global environment, so a
   signature change there re-records commonJS, erlang, beam and wasm at once. It runs alone.
2. **F1 and F5 share `codegen/erlang.zig`.** F1 owns the `untyped` branch and F5 the typed one, but
   they are the same file, the same `Emitter`, and — for the closure-mutation fold and the
   two-parameter `loop` — the same lowering. Sequence them (F1 first) or make one front.
3. **F7 moves the typed AST**, which every backend consumes, and F10 rewrites the comptime snapshot
   layout F7 is re-recording. F7 runs alone.
4. **F9 changes the harness and owns the test sources**, so every other front's
   `.snap.md.new` triage changes underneath it. It runs alone, before the fronts it would disturb.
5. **F11's comment sweeps touch files other fronts own** (the `wasm3`/`wat_runtime` leftovers sit in
   `codegen/wat.zig` and `codegen/runtime.zig`; the retired `@external(<target>, …)` vocabulary sits
   in comments across `comptime/` and `codegen/`). It is not "conflicts with nothing": each sweep
   lands **after** the front that owns the file, or is handed to that front as its last commit.
   Its frame-protocol step (`persistent_erl.zig`) owns its own file and may run any time.
6. **F12 measures libraries F7 reds.** A checker front that stops being permissive breaks library
   code F12 is fixing; F12's library commits land after F7's migration plan for them.

## Order

```
F2 cli-gate ───────┐                (widens the gate; land first — it blocks nothing)
F9 review-tooling ─┤  run alone     (changes the harness every other front triages against)
F1 comptime-dispatch ──┤            (four libraries depend on it; before F5, same file)
F3 std-surface ────────┘  run alone (re-records every backend)
        │
        ├──► F4 beam · F5 erlang · F6 wasm · F8 js-bridges     (4 in parallel)
        │
        ├──► F7 checker            run alone (moves the typed AST; executes trailing defaults)
        │      └──► F12 library-repos (the libraries F7 reds)
        │
        └──► F10 comptime-dedup    (after F7: same snapshot tree)

F11 hygiene — frame protocol any time; each comment sweep after the front that owns the file
```

Four fronts run alone and are the schedule's critical path: **F3**, **F7**, **F9** and — against
F5 only — **F1**. Everything else parallelises four ways.

## Rules for a front

- One worktree under `.tasks/<front>`, one branch `fix/<front>`, a `todo.md` at its root carrying
  the steps, the owned and forbidden paths, and the exit gate. `todo.md` is git-ignored.
- **A front never edits a file it does not own.** If a fix needs one, it stops and reports —
  that is how the parser front found the mirror bug in `comptime/infer.zig` instead of papering
  over it.
- The gate before landing: `zig build test` from a **cold** runtime cache plus `zig build
  test-libs` once F2 lands, both green in the front's own worktree.
- Landing: merge into `feat`, suite green in the main checkout, push, submodule bump in the meta
  repo, then delete the worktree and the branch.
- A refactor front (an emitter migration) lands **snapshot-byte-identical**; a fix front re-records
  only values it verified by running the program.
