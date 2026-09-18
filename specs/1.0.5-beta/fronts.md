# Fronts — 1.0.5-beta: who may touch what, when

The fronts say *what* to fix; this says *who owns which file*. A front is one worktree
(`.tasks/<name>`), one branch, one `todo.md`, one owner. Two fronts may run at the same time only
when they share **no source file and no snapshot directory** — a shared snapshot directory is the
usual trap, because one change re-records the whole directory and the two fronts then fight over
every file in it.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` unless a row says otherwise;
`cli/`, `modules/`, `libs/`, `tests/`, `scripts/`, `build.zig` and `.github/` are relative to
`repository/botopink-lang/`, and `repository/<lib>` names a sibling repository.

**This milestone is cut for parallelism.** 1.0.4-beta had one front over `comptime/**` and one over
all of `codegen/**`; here the backends are four disjoint fronts, and seven support fronts touch none
of those files. What remains serial is stated in [Order](#order), with the measurement that produced
it.

## Ownership

| Front | Source it owns | Snapshots it owns | State |
|---|---|---|---|
| **01** [`checker`](./01-checker/README.md) | `modules/compiler-core/src/comptime/{infer,types,unify,env,transform,eval,error}.zig` · `modules/compiler-core/src/parser/{decls,exprs,patterns}.zig` (steps 4, 10) · `libs/std/**`, `examples/**` (step 11 only) | `modules/compiler-core/snapshots/comptime/**` (1079) | steps 1–11; 31 of the 54 `expected-failures.txt` lines |
| **02** [`erlang`](./02-erlang/README.md) | `modules/compiler-core/src/codegen/erlang.zig` · `modules/compiler-core/src/codegen/crossModule.zig` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/erlang/**` (315) | steps 1–9; 7 of the 54 `expected-failures.txt` lines |
| **03** [`beam`](./03-beam/README.md) | `modules/compiler-core/src/codegen/beam_asm.zig` · `modules/compiler-core/src/codegen/beam/**` · `scripts/beam_export_audit.sh` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/beam/**` (314) | steps 1–5; **0** `expected-failures.txt` lines — the language suite does not run beam |
| **04** [`js`](./04-js/README.md) | `modules/compiler-core/src/codegen/commonJS.zig` · `modules/compiler-core/src/codegen/typescript.zig` · `modules/compiler-core/src/codegen/js/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/commonJS/**` (315, each carrying the TypeScript typedef; there is no separate `typescript/` directory) | steps 1–8; 7 of the 54 `expected-failures.txt` lines |
| **05** [`wasm`](./05-wasm/README.md) | `modules/compiler-core/src/codegen/wat.zig` · `modules/compiler-core/src/codegen/wat/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/wasm/**` (314) | steps 1–8; 4 of the 54 `expected-failures.txt` lines |
| **06** [`comptime-dedup`](./06-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 1079 files → 338) | not started — **runs before 01** |
| **07** [`review-backlog`](./07-review-backlog/README.md) | `src/utils/snap.zig` · `scripts/snap_audit.sh` · `src/codegen/tests/**` · `src/comptime/tests/**` except `helpers.zig` (06's) · `src/parser/tests/**` · `modules/language-server/src/tests/**` · the status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | not started — wave A after 01 + 02–05, wave B after 06 step 2 |
| **08** [`hygiene`](./08-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` (residual) · the transport-error call sites of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 14) · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | not started — steps 1, 2, 4 ready; step 3 blocks 10; steps 5–6 after their owners |
| **09** [`ecosystem-residuals`](./09-ecosystem-residuals/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs and examples | **step 1 landed 2026-09-18** — the five libraries are formatted and committed (emilia `3e7ab05`, erika `02f4344`, jhonstart `78e01ca`, rakun `6567b14`, onze already clean): 874 changed lines, token-stream equality per file, byte-identical emitted output per example, `test-libs` 11 passed / 0 failed. **Step 2 is superseded by decision 17**; step 3 after 01, step 4 after 13 |
| **10** [`cli-residuals`](./10-cli-residuals/README.md) | `modules/compiler-cli/**` **except** `src/cli/{build,run}.zig` (13's) · `modules/lib-test-runner/**` where a fix needs it | — | not started — step 1 implemented and parked in `stash@{0}` on `fix/cli`, blocked on `docs.md:78` (08 step 3.3) |
| **11** [`tooling`](./11-tooling/README.md) | `modules/language-server/**` except `src/tests/**` (07's) · `repository/vscode-extension/**`; its meta submodule pointer | `modules/language-server/snapshots/lsp/` (114) | not started — steps 1–3, 5 ready; step 4 needs a decision, step 5 after 01 |
| **12** [`language-tests`](./12-language-tests/README.md) | `repository/botopink-lang/tests/language/**` — the cells, `expected-failures.txt`, `run.sh`, `AGENTS.md` | — | not started — step 1 lands before any front deletes an expected-failure line |
| **13** [`module-identity`](./13-module-identity/README.md) | `src/codegen/crossModule.zig` · `src/codegen/{erlang.zig,beam_asm.zig,runtime.zig}` — the **module-atom sites** for steps 1–6 (carve-out of 02 and 03), the two emitters **wholesale** for steps 7–20 · `modules/compiler-cli/src/cli/{build.zig,run.zig}` (the output layout, and `botopink run --target erlang`'s `-pa`) · the module-atom lines and `buildModule` signatures of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 01) · the `tests/language/` cells for `is`, a named-type union `case` and decision 8 §7's printed form (coordinate with 12) | `snapshots/codegen/{erlang,beam}/`: **≈ 20** (half 1, names) then **188** (half 2, shapes) then **130** (half 3, value lines) | not started — **runs immediately after 14**; **02 and 03 stall while halves 2–3 run** (both emitters owned wholesale); steps 17–19 additionally after 01's N19–N22. Merged from 1.0.4-beta's 16 and 19 |
| **14** [`comptime-on-beam`](./14-comptime-on-beam/README.md) | `src/comptime/{template_eval,decorator_eval}.zig` (unowned through 1.0.4-beta) · the eval-protocol half of `src/comptime/runtime/persistent_erl.zig` (carve-out of 08) · a new `src/comptime/runtime/prelude.zig` · the two `evaluate(…)` call sites and the memo cache of `src/comptime/infer.zig` (carve-out of 01) · `ComptimeModule` / `emitComptimeModule` in `src/codegen/erlang.zig` (carve-out of 02) and, for step 3, the untyped comptime mode of `src/codegen/beam_asm.zig` (carve-out of 03) · one new script in `scripts/` (carve-out of 11) | the 48 snapshots carrying `----- COMPTIME ERLANG` in `snapshots/{codegen,comptime}/**` | **steps 0–2 landed 2026-09-18** — merged into `feat` as `bef762b`, cold gate green: the erl side of erika-linq goes 1039 ms → **49 ms** (21×, acceptance was ≤ 60), N=200 emits **1 module and 875 bytes** where it emitted 200 and 2.8 MB. 33 `COMPTIME ERLANG` cells re-recorded, nothing else; `infer.zig` never touched. **Step 3 stays deferred**, now with its blocker measured: the *typed* beam backend already fails the case the untyped mode exists for |
| **15** [`language-surface`](./15-language-surface/README.md) | `modules/compiler-core/src/parser/types.zig` · `src/lexer.zig`, `src/lexer/token.zig` · `src/print.zig` and the `ParseErrorType` enum in `src/parser.zig` · four named sites in `src/parser/exprs.zig` — `parsePostfixChain` (`:845-877`), `parsePrimary`'s grouped arm (`:1221-1227`) and the two inlined block loops (`:162-179`, `:944-951`) — a carve-out of **01** · new cases in `src/parser/tests/**` (a carve-out of **07**) | — (step 4 is strictly accepting: no snapshot may re-record) | **landed 2026-09-18** — merged into `feat` as `109f6c9`, cold gate green, 19 new parser snapshots and **no existing snapshot re-recorded**. Held back deliberately: decision 29's parser half (uncommittable alone — see the decision), decision 36 (`patterns.zig` is 01's), module-level `var` (measured only) |
| **16** [`formatter`](./16-formatter/README.md) | `modules/compiler-core/src/format.zig` · `modules/compiler-core/src/format/**` · the member-trivia and member-order fields of `modules/compiler-core/src/ast.zig` and the sites that fill them in `src/parser/decls.zig` (`parseEnumItem`, `parseFieldList`, `parseMethodDecl`) — a carve-out of **01**. **Not** `src/parser/exprs.zig`'s two inlined block loops (G5), which are **15**'s | — (the formatter has no snapshot directory; its 239 tests carry their expected text inline) | **steps 3–5 landed 2026-09-18** — merged into `feat` as `37d3dc7`, cold gate green: the `default` keyword prints, nothing reorders, trailing trivia survives, and `assertLossless` fails 4 of 5 probes on the old formatter. **09's format step is unblocked.** Open: steps 1–2, and the printer arms 15 handed over |

## Conflict matrix

`yes` = may run at the same time · `no` = shares a file or a snapshot directory, sequence them ·
`seq` = no shared file, but the order matters and the note says why. Symmetric.

|  | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **01** checker | — | seq¹ | seq¹ | seq¹ | seq¹ | no² | no³ | no⁴ | seq⁵ | yes | seq⁶ | seq⁷ | yes | no⁸ |
| **02** erlang | seq¹ | — | yes | yes | yes | yes | no³ | no⁴ | seq⁵ | seq⁹ | yes | seq⁷ | **no¹⁰** | yes |
| **03** beam | seq¹ | yes | — | yes | yes | yes | no³ | no⁴ | seq⁵ | yes | yes | seq⁷ | **no¹⁰** | yes |
| **04** js | seq¹ | yes | yes | — | yes | yes | no³ | no⁴ | seq⁵ | yes | yes | seq⁷ | seq¹¹ | yes |
| **05** wasm | seq¹ | yes | yes | yes | — | yes | no³ | no⁴ | seq⁵ | yes | yes | seq⁷ | seq¹² | yes |
| **06** dedup | no² | yes | yes | yes | yes | — | no³ | no⁴ | yes | yes | yes | yes | yes | no¹³ |
| **07** review | no³ | no³ | no³ | no³ | no³ | no³ | — | no⁴ | yes | yes | no³ | yes | no³ | no³ |
| **08** hygiene | no⁴ | no⁴ | no⁴ | no⁴ | no⁴ | no⁴ | no⁴ | — | no⁴ | seq¹⁴ | no⁴ | no⁴ | no⁴ | no⁴ |
| **09** ecosystem | seq⁵ | seq⁵ | seq⁵ | seq⁵ | seq⁵ | yes | yes | no⁴ | — | yes | yes | yes | seq¹⁵ | yes |
| **10** cli | yes | seq⁹ | yes | yes | yes | yes | yes | seq¹⁴ | yes | — | yes | yes | **no¹⁶** | yes |
| **11** tooling | seq⁶ | yes | yes | yes | yes | yes | no³ | no⁴ | yes | yes | — | yes | yes | yes |
| **12** language-tests | seq⁷ | seq⁷ | seq⁷ | seq⁷ | seq⁷ | yes | yes | no⁴ | yes | yes | yes | — | seq⁷ | yes |
| **13** module-identity | yes | **no¹⁰** | **no¹⁰** | seq¹¹ | seq¹² | yes | no³ | no⁴ | seq¹⁵ | **no¹⁶** | yes | seq⁷ | — | seq¹³ |
| **14** comptime-on-beam | no⁸ | yes | yes | yes | yes | no¹³ | no³ | no⁴ | yes | yes | yes | yes | seq¹³ | — |

1. **A backend front implements what the checker types.** No shared file — `comptime/**` against
   `codegen/<one backend>.zig` — but each backend step that lowers a decision-8 form needs the
   checker row that types it. The dependency is per row, not per front: name the row in the step.
2. **06 before 01.** Both own `snapshots/comptime/**`. Measured: the checker's partial wave in
   1.0.4-beta re-recorded 48 comptime files carrying 16 slugs — 3× the files for the same review.
   Dedup takes the directory from 1079 files to 338 first.
3. **07 owns the test sources every compiler front adds fixtures to** (`codegen/tests/**`,
   `comptime/tests/**` except `helpers.zig`, `parser/tests/**`, the language server's tests) and the
   snap tooling. Its wave A runs after 01 and 02–05, wave B after 06.
4. **08's sweeps touch every other front's files.** Each sweep lands after the front that owns the
   swept file, one commit per owning file. Its behaviour edits (the `libs/std` manifest, the comptime
   transport error) run at any time.
5. **A library compiles against the compiler.** No shared file, but 09 re-runs its cells after a
   checker or backend row changes what compiles; its decision-8 items wait for 01.
6. **11 re-records LSP snapshots after 01 renames `buildRecordDeclName`** — hover and completion print
   the name the checker builds.
7. **`tests/language/expected-failures.txt` is the shared file.** 12's step 1 re-points the 54 lines
   at this milestone's fronts **before** any front deletes one; afterwards the interaction is
   delete-only, one line in the commit that makes its test pass.
8. **14 needs a carve-out of `infer.zig`** — the two `evaluate(…)` call sites (`:2341`, `:3522`) and
   the memo cache. Granted or the front does not open.
9. **`botopink run --target erlang` runs `escript out/main.erl`**, which compiles only the file it is
   handed — so three `modules/*` cells fail on erlang with correct emitted code. The defect is 10's,
   not 02's; 02's row cites the evidence.
10. **13 owns `erlang.zig` and `beam_asm.zig` wholesale** for its second and third halves and
    re-records **318** cells in 02's and 03's snapshot directories. Its first half is four atom sites
    with no emitted shape — a carve-out, not a stop. 02 and 03 stand still while halves 2–3 run.
11. **13's third half changes the JS unit variant** (`"Dot"` → tagged), which is `commonJS.zig`, 04's
    file. One row, sequenced — see [decision 5](./decisions-pending.md#5-a-commonjs-unit-variant-is-a-bare-string).
12. **wasm has no identity at all**, so 13's third half and 05's boxed value are the *same*
    mechanism. If the tag encoding is not agreed once, the box is written twice and every boxed-value
    snapshot re-records twice — see [decision 22](./decisions-pending.md#22-wasm-has-no-identity-at-all).
13. **06 before 14**, measured: dedup first means 14 re-records 5 comptime cells; 14 first means 20,
    of which dedup then deletes 15. And 14's step 2 keys the comptime module by declaration, which is
    the key 13's `erlDeclAtom` wants — so 14 before 13 makes 13 inherit `buildModule` instead of
    fighting it.
14. **08's step 3 unblocks 10's step 1**: the `docs.md` fence decision is what lets the unresolved-
    import error land ([decision 3](./decisions-pending.md#3-the-import-fence-in-docsmd)).
15. **09 re-runs every library's erlang cell after 13** — the output layout and
    `botopink run --target erlang` both change under it.
16. **10 does not own `cli/build.zig` and `cli/run.zig`** — 13 does, for the output layout and the
    `-pa` fix. 10 owns the rest of `modules/compiler-cli/**`.
17. **15 × 01 share `parser/exprs.zig`, by named site.** 01 takes `prec.equality` in an `if`
    condition and the `_` binder; 15 takes four sites it names — `parsePostfixChain` (`:845-877`),
    the parenthesised arm (`:1221-1227`) and the two inlined block loops (`:162-179`, `:944-951`).
    No shared function. Fallback if that proves wrong: 15's step 4 after 01's step 10.
18. **16 × 01 share `parser/decls.zig`, by named function.** 16 takes `parseEnumItem`,
    `parseFieldList` and the two `method.comments` sites — the member positions and trailing trivia
    the formatter needs; 01 keeps the section-body grammar. `src/ast.zig` had no owner; 16 claims the
    trivia and member-order fields.
19. **15 before 16** on the one row they split: 15 makes the two inlined block loops parse, 16 prints
    them. Each new form should arrive with the formatter's round-trip confirmed.
20. **16 steps 3–4 before 09's format step** — the formatter **deletes the word `default`**
    (`pub default mod` → `pub mod`), so formatting the libraries first commits three files whose
    package handle is silently gone.
21. **16 claims `src/format/tests/**`**, which no front 07 list names.

## Order

```
06 comptime-dedup ──► 14 comptime-on-beam (steps 0–2) ──► 13 module-identity ──► 02 erlang ∥ 03 beam
                                   │                      (atom → policy 3 → identity)
                                   └──► 01 checker ──────────────────────────► 07 review-backlog
04 js ∥ 05 wasm ∥ 09 ecosystem ∥ 10 cli ∥ 11 tooling ∥ 12 language-tests   — beside all of it
08 hygiene's sweeps land after each swept file's owner
```

**Critical path:** `06` → `14` → `13` → `02` ∥ `03`, and `06` → `14` → `01` → `07`.

**Two pre-passes the backend fronts measured, and which the order should keep.** 02's steps 5–7
(a value `break` in a condition loop, the generator protocol, two undefined string primitives) touch
neither the print prelude, nor the module atom, nor the record representation — they re-record no
file 13 re-records, and they close **6 of 02's 7** expected-failure lines, including the milestone's
only run-time crash. And 03's BR5 moves **11 `.S` texts and no RUN LOG**: pulling it before 13 avoids
splitting an emitter that still carries a run-time template evaluator, and then deleting that
evaluator from each piece.

## Rules for a front

- One worktree under `.tasks/<front>`, one branch `fix/<front>`, a `todo.md` at its root carrying the
  steps, the owned and forbidden paths, and the exit gate. `todo.md` is git-ignored.
- **A front never edits a file it does not own.** If a fix needs one, it stops and reports. The
  carve-outs this milestone grants are listed in
  [`decisions-pending.md`](./decisions-pending.md#carve-outs-to-grant).
- The gate before landing: `scripts/gate.sh --cold` green in the front's own worktree.
- Landing: merge into `feat`, gate green in the main checkout, push, submodule bump in the meta
  repository — for a front that commits in a sibling repository, push that repository in the same
  sweep — then delete the worktree and the branch.
- A refactor front lands **snapshot-byte-identical**; a fix front re-records only values it verified
  by running the program.
- Snapshot counts in these documents are **floors measured at `botopink-lang` `c2dd780`**: the corpus
  grows as fronts add fixtures. Re-measure in your own worktree before quoting one as a target.

## Unowned items

Everything found by a front and owned by none is in
[`decisions-pending.md`](./decisions-pending.md) — this milestone's fronts claimed the rest while
being written. A new one is added there, with its evidence, the moment a front meets it.
