# Fronts — 1.0.4-beta: what can run at the same time

The fronts say *what* to fix; this says *who may touch what, when*. A front is one worktree
(`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts may run at the same time only
when they share **no source file and no snapshot directory**.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise;
`cli/`, `modules/`, `libs/`, `scripts/`, `build.zig` and `.github/` are relative to
`repository/botopink-lang/`, and `repository/<lib>` names a sibling repository.

## Ownership

| Front | Source it owns | Snapshots it owns | State |
|---|---|---|---|
| **01** [`beam`](./01-beam/README.md) | `src/codegen/beam_asm.zig`, `src/codegen/beam/beam_emitter.zig` · writes `scripts/beam_export_audit.sh` (wiring is 05's) | `snapshots/codegen/beam/` | in flight |
| **02** [`erlang`](./02-erlang/README.md) | `src/codegen/erlang.zig` (typed **and** untyped path), `src/codegen/beam/{erl_ast,erl_emitter}.zig` | `snapshots/codegen/erlang/` | in flight |
| **03** [`wasm`](./03-wasm/README.md) | `src/codegen/wat.zig`, `src/codegen/wat/**` · `src/codegen/runtime.zig` (shared, note 3) | `snapshots/codegen/wasm/` | in flight |
| **04** [`js-bridges`](./04-js-bridges/README.md) | `src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**` · `src/codegen/runtime.zig` (shared, note 3) · `src/codegen/tests/externals.zig` (H6 only) | `snapshots/codegen/commonJS/` | in flight |
| **05** [`cli-residuals`](./05-cli-residuals/README.md) | `modules/compiler-cli/**`, `modules/lib-test-runner/**`, `build.zig`, `.github/workflows/**`, `scripts/**` except `scripts/snap_audit.sh` · `src/codegen.zig` · `src/codegen/snapshot.zig` (the execute flag) · `src/comptime.zig` · the four `codegenEmit` sites (step 2) · `src/comptime/tests/decorator_regression.zig` | — | not started |
| **06** [`checker`](./06-checker/README.md) | `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` · `src/parser/{decls,exprs,patterns}.zig` | `snapshots/comptime/**`, and it can move **all four** codegen directories and LSP completion snapshots | not started |
| **07** [`comptime-dedup`](./07-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 3 of 4 copies deleted) | not started |
| **08** [`review-backlog`](./08-review-backlog/README.md) | `src/utils/snap.zig`, `scripts/snap_audit.sh`, `src/codegen/tests/**`, `src/comptime/tests/**`, `src/parser/tests/**`, `modules/language-server/src/tests/**` (minus the carve-outs of 04, 05, 07) · status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | steps 1–3 delivered as 1.0.2-beta review-tooling |
| **09** [`hygiene`](./09-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` · `meta:build.zig`, root `test_pub.zig`/`test_format.zig`, `modules/*/build.zig` + `.zon` · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | step 1 delivered |
| **10** [`library-repos`](./10-library-repos/README.md) | `repository/erika/**`, `repository/emilia/**`, one line in `repository/{jhonstart,onze}/.github/workflows/test.yml` | — | 7a, 7e–7h delivered |
| **11** [`dead-keywords-residual`](./11-dead-keywords-residual/README.md) | `repository/jhonstart/src/{router,server}.d.bp` + call sites · `repository/vscode-extension/syntaxes/botopink.tmLanguage.json` (keyword pattern) | — | compiler half delivered |
| **12** [`surface-cutover`](./12-surface-cutover/README.md) | `modules/compiler-core/src/**`, `modules/language-server/src/**` (compile-level), `cli/resolver.zig`, `libs/std/**`, `examples/**` | `modules/compiler-core/snapshots/**`, LSP snapshots | not started |
| **13** [`ecosystem-migration`](./13-ecosystem-migration/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs | not started |
| **14** [`tooling-and-docs`](./14-tooling-and-docs/README.md) | `modules/language-server/src/engine.zig` (user-facing texts, completions, symbol kinds), `repository/vscode-extension/**`, botopink-lang user docs | LSP hover/completion/symbol snapshots | not started |

`libs/std/**` code has **no owner** from now until 12 — 1.0.2-beta std-surface has landed. A fix
that needs a `libs/std` edit stops and reports; the maintainer assigns it per case.
`scripts/known-red-libs.txt` is 05's file, but the front that turns a known-red cell green deletes
its line in its own landing commit.

## Conflict matrix

`yes` = may run at the same time · `no` = shares a file or a snapshot directory: sequence them ·
`seq` = no shared file, but the milestone orders them (a decision or a compiler dependency). The
matrix is symmetric; the order is in the notes and in [Order](#order).

|  | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **01** | — | yes | yes | yes | yes¹ | no⁴ | yes | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **02** | yes | — | yes | yes² | yes¹ | no⁴ | yes | no⁷ | no⁸ | seq¹⁰ | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **03** | yes | yes | — | yes³ | yes¹ | no⁴ | yes | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **04** | yes | yes² | yes³ | — | yes¹ | no⁴ | yes | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **05** | yes¹ | yes¹ | yes¹ | yes¹ | — | no⁵ | yes | yes | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **06** | no⁴ | no⁴ | no⁴ | no⁴ | no⁵ | — | no⁶ | no⁷ | no⁸ | no⁹ | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **07** | yes | yes | yes | yes | yes | no⁶ | — | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **08** | no⁷ | no⁷ | no⁷ | no⁷ | yes | no⁷ | no⁷ | — | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **09** | no⁸ | no⁸ | no⁸ | no⁸ | no⁸ | no⁸ | no⁸ | no⁸ | — | seq¹⁰ | seq¹¹ | no¹² | no¹³ | no¹³ |
| **10** | yes | seq¹⁰ | yes | yes | yes | no⁹ | yes | yes | seq¹⁰ | — | seq¹¹ | no¹² | no¹³ | seq¹¹ |
| **11** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | — | yes | no¹³ | no¹³ |
| **12** | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | yes | — | no¹³ | no¹³ |
| **13** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | no¹³ | no¹³ | no¹³ | no¹³ | — | yes |
| **14** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | no¹³ | seq¹¹ | no¹³ | no¹³ | yes | — |

1. **05 step 2 edits one site in each backend file** (the `codegenEmit` early `continue`). Steps 1,
   3–6 touch none of 01–04's files and run beside them now; step 2 waits for all four to land.
2. **02 × 04 — one step each is not file-local.** The `#[@result]` wrap (erlang E8, commonJS JS-1's
   `throw_inside_case_arm`) lives in `src/comptime/transform.zig` — 06's file — and re-records both
   snapshot directories. Neither front starts it without agreeing the owner with the maintainer;
   everything else in the two fronts is disjoint.
3. **03 × 04 share `src/codegen/runtime.zig`.** Both are in flight, and both first steps add a block
   to it (wasm's `RUNTIME TRAP (wasmtime):`, js-bridges' `COMPILE ERROR (node --check):`), each
   bumping `HARNESS_VERSION`. The edits are additive and in different functions: the first to land
   keeps its commit, the second rebases, re-bumps `HARNESS_VERSION` and re-records only its own
   directory. Nobody else edits `runtime.zig` this milestone.
4. **06 moves the typed AST every backend consumes** and can re-record all four codegen snapshot
   directories. It runs after 01–04 and beside nothing that owns a codegen file or snapshot.
5. **05 × 06:** 05 step 2 must land byte-identical before 06 re-records, and 05 step 3's
   `print((1);` location fix may land in `src/parser/exprs.zig` (06's file). Sequence 05's steps 2–3
   first.
6. **06 × 07 share `snapshots/comptime/**`**: 06 re-records it, 07 restructures it. 06 first — its
   row counts and migration plan are measured against today's layout.
7. **08 owns the test sources** the fronts 01–07 add fixtures to, and its rows cite snapshots they
   re-record. Wave A (codegen reports) runs after 06; wave B (comptime reports) after 07 step 2. 05's
   `decorator_regression.zig` and 04's `externals.zig` edits are carve-outs and do not collide.
8. **09's comment sweeps touch every other front's files.** Each sweep lands after the front that
   owns the swept file, one commit per owning file; its behaviour edits (group B's non-root build
   files, the `persistent_erl.zig` residual) and the decisions (step 6) run at any time. Group B's
   root `build.zig`/CI edits wait for 05; group A waits for 03's `executeWat` decision.
9. **06's G1 migrates library code** (emilia's 92 sites, plus jhonstart and onze) while 10 adds
   emilia's gate. Land 10's emilia step first, so the migration commits pass through the gate —
   or hand emilia's migration commit to 10.
10. **10 waits on decisions, not files:** erika on 02's H3; emilia on 09's decision 5.5.
11. **The surface cutover starts after every 1.0.2-derived front (01–10) closes** — 12 touches every
    file those fronts own, and the library gate cannot be read while they are open. 11 shares no
    file with 12 and runs beside it.
12. **12 owns all of `modules/compiler-core/src/**`**, the LSP source, `libs/std/**` and
    `examples/**` — every compiler front's files.
13. **10 × 13** share erika and emilia (10 lands first — it is a 1.0.2-derived front); **11 × 13** share jhonstart; **11 × 14** share the tmLanguage keyword pattern; **12 × 13** is a
    compiler dependency (the libraries compile only against 12's compiler); **12 × 14** share
    `language-server/src/engine.zig`; **09 × 13/14** would share library and user docs if a sweep
    were still open. Sequence: 11 and 12 first, then 13 ∥ 14.

## Order

```
01 beam ─────────┐
02 erlang ───────┤  in flight since 2026-09-16 — 4 in parallel
03 wasm ─────────┤
04 js-bridges ───┘
05 cli-residuals ─── steps 1, 3–6 beside them; step 2 after all four ──┐
                                                                        ▼
                                      06 checker (alone) ──► 07 comptime-dedup ──► 08 review-backlog
                                                                                   (wave A after 06,
                                                                                    wave B after 07)
10 library-repos ─── erika after 02 · emilia after 09's decision 5.5 · before 06's G1 (emilia)
09 hygiene ───────── decisions now · each sweep after the file's owner · closes last of 01–10
                                                                        │
                              all of 01–10 closed ──────────────────────┘
                                   ├──► 11 dead-keywords-residual ─┐
                                   └──► 12 surface-cutover (alone) ┴──► 13 ecosystem-migration
                                                                        14 tooling-and-docs   (2 in parallel)
```

**Critical path:** 01–04 → 05 step 2 → **06** → **07** → 08 → 09's last sweeps → **12** → 13 ∥ 14.
06 and 12 run alone; 07 runs after 06 on the same snapshot tree.

## Rules for a front

- One worktree under `.tasks/<front>`, one branch `fix/<front>`, a `todo.md` at its root carrying
  the steps, the owned and forbidden paths, and the exit gate. `todo.md` is git-ignored.
- **A front never edits a file it does not own.** If a fix needs one, it stops and reports.
- The gate before landing: `scripts/gate.sh --cold` (zig build, cold `zig build test`, `test-cli`,
  `test-libs`) green in the front's own worktree.
- Landing: merge into `feat`, gate green in the main checkout, push, submodule bump in the meta repo
  — for a front that commits in a sibling repository, push that repository in the same sweep —
  then delete the worktree and the branch.
- A refactor front lands **snapshot-byte-identical**; a fix front re-records only values it verified
  by running the program.

<a id="unowned-items"></a>

## Unowned items

Found by a front and owned by none. Each needs the maintainer to assign it (or push it to the next
milestone) before the front that would otherwise meet it closes.

| Item | Where | Found by | Suggested owner |
|---|---|---|---|
| **`hover_interface_method`**: should the hover footer name the declaring interface (`Signed`) or the receiver's (`I32`)? An open decision | `modules/language-server/src/engine.zig` | 1.0.2-beta review-tooling (report 3.12) | decision first; then 14 (it owns user-facing `engine.zig` texts) or earlier as a one-line follow-up |
| A missing dependency swallowed by the language server, if still open after 05 step 5 | `modules/language-server/src/project_graph.zig` (~`:171`) | 1.0.2-beta library-repos | none until 12; a one-line follow-up |
| **`$0` (commonJS) vs `$self` (erlang)** naming the first template argument of an `#[@External…]` template | the commonJS and erlang template renderers | 1.0.2-beta std-surface | a decision; [`06-checker/external-annotations.md`](./06-checker/external-annotations.md#6-recommendation) rule T8 (`$self` on interface methods, `$N` on `declare fn`) is the recommended answer — implementation then spans 02 and 04 |
| rakun's records get no `module.exports`: the emitted `bootstrap.js` does not export `Rakun` | `src/codegen/commonJS.zig` (likely) | 1.0.2-beta library-repos | 04 if still open, else a follow-up; verified by [`10-library-repos`](./10-library-repos/README.md) step 4 |
| The block-as-value lowerings left dead in all four backends once 06 enforces decision 2 | `erlang.zig`, `beam_asm.zig`, `commonJS.zig`, `wat.zig` | decision 2 | a follow-up after 06 (the backend fronts will have closed) |
| `wrong-output` rows that survive 08's wave A after their backend front has closed | the backend files | 08 | the next milestone, by name |
| `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (owned by 1.0.2-beta comptime-dispatch, landed) | — | — | 06 claims them if types-as-values A4 takes the `erl` path; 09 may take the transport-error one-liner |
| `libs/std/**` code | — | — | none until 12; stop and report |

Two items that were unowned in 1.0.2-beta now have owners: `comptime/error.zig` rendering
`┌─ :L:C` with no file name → [`06-checker`](./06-checker/README.md) N9; the `erl.stderr.log`
shared across processes → [`09-hygiene`](./09-hygiene/README.md) step 1 residual.

<a id="old-front-numbers"></a>

## Old front numbers

The carried deep dives cite fronts by their old numbers. Map them here.

| Old | Name | In 1.0.4-beta |
|---|---|---|
| 1.0.2-beta F1 | comptime-dispatch | **delivered** (steps 1, 2); step 3 → [`06-checker`](./06-checker/README.md) N1; the beam half of step 2 → [`01-beam`](./01-beam/README.md) H3 |
| 1.0.2-beta F2 | cli-gate | **delivered**; residuals → [`05-cli-residuals`](./05-cli-residuals/README.md) |
| 1.0.2-beta F3 | std-surface | **delivered**; residuals → 01 H7, 02 H6, 04 H2–H4/H6, 05 step 5; its `external-annotations.md` → [`06-checker`](./06-checker/external-annotations.md) |
| 1.0.2-beta F4 | beam | [`01-beam`](./01-beam/README.md) |
| 1.0.2-beta F5 | erlang | [`02-erlang`](./02-erlang/README.md) |
| 1.0.2-beta F6 | wasm | [`03-wasm`](./03-wasm/README.md) |
| 1.0.2-beta F7 | checker | [`06-checker`](./06-checker/README.md) |
| 1.0.2-beta F8 | js-bridges | [`04-js-bridges`](./04-js-bridges/README.md) |
| 1.0.2-beta F9 | review-tooling | steps 1–3 **delivered**; step 4 → [`08-review-backlog`](./08-review-backlog/README.md) |
| 1.0.2-beta F10 | comptime-dedup | [`07-comptime-dedup`](./07-comptime-dedup/README.md) |
| 1.0.2-beta F11 | hygiene | [`09-hygiene`](./09-hygiene/README.md) (step 1 **delivered**) |
| 1.0.2-beta F12 | library-repos | [`10-library-repos`](./10-library-repos/README.md) (7a, 7e–7h **delivered**) |
| 1.0.3-beta F1 | dead-keywords | compiler half **delivered**; residual → [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) |
| 1.0.3-beta F2 | surface-cutover | [`12-surface-cutover`](./12-surface-cutover/README.md) |
| 1.0.3-beta F3 | ecosystem-migration | [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) |
| 1.0.3-beta F4 | tooling-and-docs | [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) |
