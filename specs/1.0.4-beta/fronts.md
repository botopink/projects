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
| **01** [`backend-residuals`](./01-backend-residuals/README.md) | `src/codegen/beam_asm.zig`, `src/codegen/beam/**`, `src/codegen/erlang.zig`, `src/codegen/wat.zig`, `src/codegen/wat/**`, `src/codegen/commonJS.zig`, `src/codegen/typescript.zig`, `src/codegen/js/**`, `src/codegen/runtime.zig` (note 3) · the `KNOWN` notes of its fixtures in `src/codegen/tests/**` (carve-out) — its beam, wasm and commonJS rows are file-disjoint and may run as three worktrees | `snapshots/codegen/{beam,erlang,wasm,commonJS}/` | steps 1–3 **delivered** 2026-09-17; steps 4 (decision 1a) and 5 (BR5) open |
| **05** [`cli-residuals`](./05-cli-residuals/README.md) | `modules/compiler-cli/**`, `modules/lib-test-runner/**`, `build.zig`, `.github/workflows/**`, `scripts/**` except `scripts/snap_audit.sh` · `src/codegen.zig` · `src/codegen/snapshot.zig` (the execute flag) · `src/comptime.zig` · the four `codegenEmit` sites (step 2) · `src/comptime/tests/decorator_regression.zig` | — | not started |
| **06** [`checker`](./06-checker/README.md) | `src/comptime/{infer,types,env,unify,transform,eval,error}.zig` · `src/parser/{decls,exprs,patterns}.zig` | `snapshots/comptime/**`, and it can move **all four** codegen directories and LSP completion snapshots | not started |
| **07** [`comptime-dedup`](./07-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 3 of 4 copies deleted) | not started |
| **08** [`review-backlog`](./08-review-backlog/README.md) | `src/utils/snap.zig`, `scripts/snap_audit.sh`, `src/codegen/tests/**`, `src/comptime/tests/**`, `src/parser/tests/**`, `modules/language-server/src/tests/**` (minus the carve-outs of 01, 05, 07) · status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | steps 1–3 delivered as 1.0.2-beta review-tooling |
| **09** [`hygiene`](./09-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` · `meta:build.zig`, root `test_pub.zig`/`test_format.zig`, `modules/*/build.zig` + `.zon` · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | step 1 delivered |
| **10** [`library-repos`](./10-library-repos/README.md) | `repository/erika/**`, `repository/emilia/**`, one line in `repository/{jhonstart,onze}/.github/workflows/test.yml` | — | 7a, 7e–7h delivered |
| **11** [`dead-keywords-residual`](./11-dead-keywords-residual/README.md) | `repository/jhonstart/src/{router,server}.d.bp` + call sites · `repository/vscode-extension/syntaxes/botopink.tmLanguage.json` (keyword pattern) | — | compiler half delivered |
| **12** [`surface-cutover`](./12-surface-cutover/README.md) | `modules/compiler-core/src/**`, `modules/language-server/src/**` (compile-level), `cli/resolver.zig`, `libs/std/**`, `examples/**` | `modules/compiler-core/snapshots/**`, LSP snapshots | not started |
| **13** [`ecosystem-migration`](./13-ecosystem-migration/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs | not started |
| **14** [`tooling-and-docs`](./14-tooling-and-docs/README.md) | `modules/language-server/src/engine.zig` (user-facing texts, completions, symbol kinds), `repository/vscode-extension/**`, botopink-lang user docs | LSP hover/completion/symbol snapshots | not started |

`libs/std/**` code has **no owner** from now until 12 — 1.0.2-beta std-surface has landed. A fix
that needs a `libs/std` edit stops and reports; the maintainer assigns it per case. The
highest-value item in the milestone sits there: [unowned items](#unowned-items), first row.
`scripts/known-red-libs.txt` is 05's file, but the front that turns a known-red cell green deletes
its line in its own landing commit.

## Conflict matrix

`yes` = may run at the same time · `no` = shares a file or a snapshot directory: sequence them ·
`seq` = no shared file, but the milestone orders them (a decision or a compiler dependency). The
matrix is symmetric; the order is in the notes and in [Order](#order).

|  | 01 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **01** | — | yes¹ | no⁴ | yes | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **05** | yes¹ | — | no⁵ | yes | yes | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **06** | no⁴ | no⁵ | — | no⁶ | no⁷ | no⁸ | no⁹ | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **07** | yes | yes | no⁶ | — | no⁷ | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **08** | no⁷ | yes | no⁷ | no⁷ | — | no⁸ | yes | seq¹¹ | no¹² | seq¹¹ | seq¹¹ |
| **09** | no⁸ | no⁸ | no⁸ | no⁸ | no⁸ | — | seq¹⁰ | seq¹¹ | no¹² | no¹³ | no¹³ |
| **10** | yes | yes | no⁹ | yes | yes | seq¹⁰ | — | seq¹¹ | no¹² | no¹³ | seq¹¹ |
| **11** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | — | yes | no¹³ | no¹³ |
| **12** | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | no¹² | yes | — | no¹³ | no¹³ |
| **13** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | no¹³ | no¹³ | no¹³ | no¹³ | — | yes |
| **14** | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | seq¹¹ | no¹³ | seq¹¹ | no¹³ | no¹³ | yes | — |

1. **05 step 2 edits one site in each backend file** (the `codegenEmit` early `continue`) — files 01
   owns. Steps 1, 3–6 touch none of them. Step 2 is one byte-identical commit: land it before 01
   opens a backend's rows or between two of them, never while a 01 worktree holds that file.
2. **The `#[@result]` wrap left the backend fronts.** Erlang's E8 and commonJS's
   `throw_inside_case_arm` shape are decided in `src/comptime/transform.zig`, 06's file; the erlang
   landing left it open. It is [`06-checker`](./06-checker/README.md#step-0--rows-added-in-104-beta)
   N10 and re-records erlang and commonJS with 06's other codegen moves — 01 does not take it.
3. **`src/codegen/runtime.zig` is 01's.** Both harness blocks landed (`COMPILE ERROR (node --check):`,
   `RUNTIME TRAP (wasmtime):`, `HARNESS_VERSION = "3-wasm-runs"`). A change to it bumps
   `HARNESS_VERSION` in the same commit; with 01's backends split across worktrees, one worktree holds
   the file at a time.
4. **06 moves the typed AST every backend consumes** and can re-record all four codegen snapshot
   directories. It runs after 01 and beside nothing that owns a codegen file or snapshot; 01's rows
   meet 06 only where they are checker questions, and those are routed to 06 (N5, N6, N10–N15).
5. **05 × 06:** 05 step 2 must land byte-identical before 06 re-records, and 05 step 3's
   `print((1);` location fix may land in `src/parser/exprs.zig` (06's file). Sequence 05's steps 2–3
   first.
6. **06 × 07 share `snapshots/comptime/**`**: 06 re-records it, 07 restructures it. 06 first — its
   row counts and migration plan are measured against today's layout.
7. **08 owns the test sources** the fronts 01–07 add fixtures to, and its rows cite snapshots they
   re-record. Wave A (codegen reports) runs after 06; wave B (comptime reports) after 07 step 2. 05's
   `decorator_regression.zig` and 01's `KNOWN` notes are carve-outs and do not collide.
8. **09's comment sweeps touch every other front's files.** Each sweep lands after the front that
   owns the swept file, one commit per owning file; its behaviour edits (group B's non-root build
   files, the `persistent_erl.zig` residual) and the decisions (step 6) run at any time. Group B's
   root `build.zig`/CI edits wait for 05; group A waits for 03's `executeWat` decision.
9. **06's G1 migrates library code** (emilia's 92 sites, plus jhonstart and onze) while 10 adds
   emilia's gate. Land 10's emilia step first, so the migration commits pass through the gate —
   or hand emilia's migration commit to 10.
10. **10 waits on a decision, not files:** emilia on 09's decision 5.5 (erika's `String.split("")`
    blocker landed).
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
01 backend-residuals ─── beam · wasm · commonJS in parallel ───────────┐
05 cli-residuals ─── steps 1, 3–6 now; step 2 now, against 01's files ─┤
                                                                        ▼
                                      06 checker (alone) ──► 07 comptime-dedup ──► 08 review-backlog
                                                                                   (wave A after 06,
                                                                                    wave B after 07)
10 library-repos ─── erika now · emilia after 09's 5.5 · before 06's G1
09 hygiene ───────── decisions now · each sweep after the file's owner · closes last of 01–10
                                                                        │
                              all of 01–10 closed ──────────────────────┘
                                   ├──► 11 dead-keywords-residual ─┐
                                   └──► 12 surface-cutover (alone) ┴──► 13 ecosystem-migration
                                                                        14 tooling-and-docs   (2 in parallel)
```

The first 01–04 (beam, erlang, wasm, js-bridges) landed 2026-09-17.

**Critical path:** 01 ∥ 05 step 2 → **06** → **07** → 08 → 09's last sweeps → **12** → 13 ∥ 14.
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
| `Array.chunked` / `Array.sliding` are written with `while`, which checked code rejects as not in scope — **decided 2026-09-17: rewrite them with `loop`** | `libs/std/src/primitives.bp` | 1.0.4-beta erlang | assigned by the maintainer as a one-off `libs/std` edit (like std-split) |
| JS-4's codegen half: once 06 N11 lands, a `ctor` destructuring lowers to a real JS test-plus-destructure and `Pattern.match` goes — [`01-backend-residuals/pattern-binding.md`](./01-backend-residuals/pattern-binding.md) | `src/codegen/commonJS.zig`, `src/codegen/js/**` | 1.0.4-beta js-bridges | 01 if still open, else a follow-up after 06 |
| **`hover_interface_method`**: should the hover footer name the declaring interface (`Signed`) or the receiver's (`I32`)? An open decision | `modules/language-server/src/engine.zig` | 1.0.2-beta review-tooling (report 3.12) | decision first; then 14 (it owns user-facing `engine.zig` texts) or earlier as a one-line follow-up |
| A missing dependency (`:171`) and an unreadable `files` entry (`:210`) swallowed by the language server with `catch continue` — the CLI half landed with 05 step 5 | `modules/language-server/src/project_graph.zig` | 1.0.2-beta library-repos, re-confirmed by 05 | none until 12; a one-line follow-up |
| The block-as-value lowerings left dead in all four backends once 06 enforces decision 2 | `erlang.zig`, `beam_asm.zig`, `commonJS.zig`, `wat.zig` | decision 2 | 01 if still open when 06 lands N6, else a follow-up |
| `wrong-output` rows that survive 08's wave A after their backend front has closed | the backend files | 08 | the next milestone, by name |
| `src/comptime/template_eval.zig`, `src/comptime/decorator_eval.zig` (owned by 1.0.2-beta comptime-dispatch, landed) | — | — | 06 claims them if types-as-values A4 takes the `erl` path; 09 may take the transport-error one-liner |
| `libs/std/**` code, beyond the three rows above | — | — | none until 12; stop and report |

Two items that were unowned in 1.0.2-beta now have owners: `comptime/error.zig` rendering
`┌─ :L:C` with no file name → [`06-checker`](./06-checker/README.md) N9; the `erl.stderr.log`
shared across processes → [`09-hygiene`](./09-hygiene/README.md) step 1 residual.

<a id="old-front-numbers"></a>

## Old front numbers

The carried deep dives cite fronts by their old numbers. Map them here.

| Old | Name | In 1.0.4-beta |
|---|---|---|
| 1.0.2-beta F1 | comptime-dispatch | **delivered** (steps 1, 2; the beam half of step 2 with 1.0.4-beta beam); step 3 → [`06-checker`](./06-checker/README.md) N1 |
| 1.0.2-beta F2 | cli-gate | **delivered**; residuals → [`05-cli-residuals`](./05-cli-residuals/README.md) |
| 1.0.2-beta F3 | std-surface | **delivered**; its backend residuals delivered with 1.0.4-beta beam, erlang, js-bridges; 05 step 5; its `external-annotations.md` → [`06-checker`](./06-checker/external-annotations.md) |
| 1.0.2-beta F4 | beam | = 1.0.4-beta first 01 beam, **delivered** `a743955`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F5 | erlang | = 1.0.4-beta 02 erlang, **delivered** `42429dc`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md#routed-out) |
| 1.0.2-beta F6 | wasm | = 1.0.4-beta 03 wasm, **delivered** `ed15323`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F7 | checker | [`06-checker`](./06-checker/README.md) |
| 1.0.2-beta F8 | js-bridges | = 1.0.4-beta 04 js-bridges, **delivered** `bd7836c`; residuals → [`01-backend-residuals`](./01-backend-residuals/README.md) |
| 1.0.2-beta F9 | review-tooling | steps 1–3 **delivered**; step 4 → [`08-review-backlog`](./08-review-backlog/README.md) |
| 1.0.2-beta F10 | comptime-dedup | [`07-comptime-dedup`](./07-comptime-dedup/README.md) |
| 1.0.2-beta F11 | hygiene | [`09-hygiene`](./09-hygiene/README.md) (step 1 **delivered**) |
| 1.0.2-beta F12 | library-repos | [`10-library-repos`](./10-library-repos/README.md) (7a, 7e–7h **delivered**) |
| 1.0.4-beta 01–04 (until 2026-09-17) | beam, erlang, wasm, js-bridges | **delivered**; handoff ids (`B…`, `E…`, `W…`, `C…`, `JS-…`, `H…`) cited by the carried documents are closed unless [`01-backend-residuals`](./01-backend-residuals/README.md) names them |
| 1.0.3-beta F1 | dead-keywords | compiler half **delivered**; residual → [`11-dead-keywords-residual`](./11-dead-keywords-residual/README.md) |
| 1.0.3-beta F2 | surface-cutover | [`12-surface-cutover`](./12-surface-cutover/README.md) |
| 1.0.3-beta F3 | ecosystem-migration | [`13-ecosystem-migration`](./13-ecosystem-migration/README.md) |
| 1.0.3-beta F4 | tooling-and-docs | [`14-tooling-and-docs`](./14-tooling-and-docs/README.md) |
