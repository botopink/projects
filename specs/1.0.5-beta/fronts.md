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
| **02** [`erlang`](./02-erlang/README.md) | `modules/compiler-core/src/codegen/erlang.zig` · `modules/compiler-core/src/codegen/crossModule.zig` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/erlang/**` (315) | **steps 5 and 6 landed 2026-09-18** — merged as `27fd6ea`: a condition loop's `break <value>` is the loop's value (`a9e9d03`, and with it a loop in value position that never terminated) and a yielding condition loop collects (`f547f99f`, the milestone's **only run-time crash**). Five `expected-failures.txt` lines deleted, suite 253 → **259 passed / 53 expected / 0 failed**, and **zero snapshots moved** — the measurement the README asked for before landing ahead of 13. Steps 4 and 7 **do not reproduce** (the surviving line is decision 45's, in the checker). Also `32dc984` — a method on an imported **enum** names the module that exports it, the enum half of `7783fd6`/`1193d3c` that front 03 found: both candidates were missing (the `enum` kind in `imported_types` *and* any link-index fallback), and erlang's self-call guard needed the source **path** as well as the atom, or `std/dict` called itself remotely. 1 snapshot moved, RUN LOG `COMPILE ERROR` → `1 / 16 / 42`. Open: steps 1, 2, 3, 8, 9 — all after 01 or 13 |
| **03** [`beam`](./03-beam/README.md) | `modules/compiler-core/src/codegen/beam_asm.zig` · `modules/compiler-core/src/codegen/beam/**` · `scripts/beam_export_audit.sh` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/beam/**` (314) | **steps 2–5 landed 2026-09-18** — merged as `f8d97f9`: the print formatter (`416c979`, 163 cells), an imported type's method as a remote call (`448b935`, `{badfun, #{…}}` → `1`/`2`), the three cross-module shapes pinned by running them (`35e91b1`), and **a defect no snapshot could see** — `loop ([1, 2, 3]) { … }` emitted `.S` that did not assemble (`{invalid_store,{y,0}}`), because no cell in 314 beam snapshots loops over a literal (`841e25d`). 8 snapshots added, **0** re-recorded; 4 `expected-failures.txt` lines deleted, `--target beam` **18 / 16 / 0**. `make_fun3`: 13 hits, all comments, 8 build sites, **0** a block as a value — so 01 step 8's R7 has no producer here. **BR5 stays blocked and the block is structural**: nothing in this compiler parses Erlang. Open: D6 (beam is now the only backend without a condition loop's value `break`) and step 1 F1/F5 |
| **04** [`js`](./04-js/README.md) | `modules/compiler-core/src/codegen/commonJS.zig` · `modules/compiler-core/src/codegen/typescript.zig` · `modules/compiler-core/src/codegen/js/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/commonJS/**` (315, each carrying the TypeScript typedef; there is no separate `typescript/` directory) | **the handover, the index and steps 2/6/8 landed 2026-09-18** — merged as `1379659`: the three `case` defects fixed (arm fall-through with them), D4, T3, the IIFE sites classified (11 text hits / 10 build sites / **1** block-as-value, not 27), and the optional guard that made `o.inner?.v ?? 9` answer `undefined`. Two `expected-failures.txt` lines deleted. Open: step 1 F2–F4 (with 13), step 7 (needs 01 R5), `d["k"]` (question 46) |
| **05** [`wasm`](./05-wasm/README.md) | `modules/compiler-core/src/codegen/wat.zig` · `modules/compiler-core/src/codegen/wat/**` · the `KNOWN` notes and new fixtures of its rows in `src/codegen/tests/**` | `modules/compiler-core/snapshots/codegen/wasm/**` (314 → **328**) | **steps 1–8 closed 2026-09-18** — merged as `1b65ffda` off `fix/wasm` (13 commits): the `case` row, decision 30's index **including** the nested read and a slice's `.length`, `break`'s value, tuple `==`, the string case primitives, a record reaching `@print` trapping instead of answering its address, and **step 3, whose suspect was wrong** — the `forEach` accumulator works; two `?T` writer/reader disagreements did it (an assignment into a declared `?T` never boxed, and a method's declared return type was never registered under the symbol its call emits), and fixing the registration also fixed `hasKey`, `values` and `print`. **Step 7 turned out to be implemented** (lambdas already lift into a table; the gap was a function value in an *aggregate slot*) and **step 8 is struck** with front 04's own measurement: 0 sites a block can reach. 2 `expected-failures` lines deleted, suite **261 / 51 / 0**. Open: step 1 F1 (ready — its blocker is stale, the line is this front's own) and two address-printed string shapes |
| **06** [`comptime-dedup`](./06-comptime-dedup/README.md) | `src/comptime/snapshot.zig`, `src/comptime/tests/helpers.zig` | `snapshots/comptime/**` (layout: 1079 files → 338) | not started — **runs before 01** |
| **07** [`review-backlog`](./07-review-backlog/README.md) | `src/utils/snap.zig` · `scripts/snap_audit.sh` · `src/codegen/tests/**` · `src/comptime/tests/**` except `helpers.zig` (06's) · `src/parser/tests/**` · `modules/language-server/src/tests/**` · the status lines of the 1.0.1-beta reports (meta repo) | — (moves a snapshot only by renaming its test) | not started — wave A after 01 + 02–05, wave B after 06 step 2 |
| **08** [`hygiene`](./08-hygiene/README.md) | `src/comptime/runtime/persistent_erl.zig` (residual) · the transport-error call sites of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 14) · `libs/std/botopink.json`, `libs/std/AGENTS.md` · `examples/**`, `README.md`, `docs.md`, every `AGENTS.md`, comments (after owners) | — | **steps 1–5 landed 2026-09-18** — merged as `6df4eed`, every row re-derived by *running* the form: `docs.md`'s "Decided, not yet implemented" table goes from twelve rows to **five** (nine were wrong, and six forms were documented *only* there, so three new fences teach them), `libs/std/AGENTS.md`'s whole "Known red" table was three stale rows (re-measured: 13 passed / 0 failed on both targets), 5 of the 19 `primitives.d.bp` comments swept, and step 5's box closed on front 14's `19a3b01`. Steps 1 and 4 needed **no edit** and say why. **Front 10 needs nothing further from step 3** — `docs.md:78` and 10's unresolved-import error are both already in `feat`. Open: step 6 (front 07's files) and the rest of 2.1 / 3.1, behind fronts 01, 02 and 07 |
| **09** [`ecosystem-residuals`](./09-ecosystem-residuals/README.md) | `repository/{emilia,erika,jhonstart,onze,rakun}/**`; their meta submodule pointers | the libraries' own test outputs and examples | **step 1 landed 2026-09-18** — the five libraries are formatted and committed (emilia `3e7ab05`, erika `02f4344`, jhonstart `78e01ca`, rakun `6567b14`, onze already clean): 874 changed lines, token-stream equality per file, byte-identical emitted output per example, `test-libs` 11 passed / 0 failed. **Step 2 is superseded by decision 17**; step 3 after 01, step 4 after 13 |
| **10** [`cli-residuals`](./10-cli-residuals/README.md) | `modules/compiler-cli/**` **except** `src/cli/{build,run}.zig` (13's) · `modules/lib-test-runner/**` where a fix needs it | — | **closed 2026-09-18** — merged as `d5e14ad`: all three code steps were **already in `feat`** (`ccc0ab1` step 1, `7207f4f` step 2, `315a38f` step 3, and R3 closed by front 11's `ae6476c`), each re-verified by running a probe rather than by reading the commit. `stash@{0}` was read and **left in place**: it is an obsolete *subset* of `feat`, so applying it would regress. What the session produced is step 4's row for front 13, measured: `escript` cannot be fixed with `-pa` (`illegal operation on a directory`), so `cli/run.zig` becomes `erlc -o <out_dir>` recursively + `erl -noshell -pa <out_dir> -eval "<module>:main([]), halt()."` — all four projects then print what they mean. Two riders: the entry must be `main([])` (`main/0` is `pub`-gated) and the crash exit status moves `127` → `1`, which is [question 56](./decisions-pending.md) |
| **11** [`tooling`](./11-tooling/README.md) | `modules/language-server/**` except `src/tests/**` (07's) · `repository/vscode-extension/**`; its meta submodule pointer | `modules/language-server/snapshots/lsp/` (114) | **landed 2026-09-18** — steps 1–4 were already in `feat` (step 4's decision was decision 7 all along); re-verifying them found the language server rendering the checker's internal `optional<T>` into hovers, inlay hints, signature help and a code action that wrote it **into the user's file** (`3c5e877`, 4 new snapshots / 0 re-recorded), and the grammar painting `??` as two optional markers (`dd46d1f`). Step 5 still after 01 — and its blast radius is **one** snapshot line, measured |
| **12** [`language-tests`](./12-language-tests/README.md) | `repository/botopink-lang/tests/language/**` — the cells, `expected-failures.txt`, `run.sh`, `AGENTS.md` | — | **landed 2026-09-18** — step 1 had already landed at `7ab6a55`, so nothing was blocked; the header is now a run (250 passed / 61 expected / 0 failed, beam 14/20/0), `AGENTS.md`'s not-parsing table lost 5 of its 7 rows, and 7 cells cover decisions 28/30/33. Four defects found, one of them beam **dropping an index silently with exit 0** |
| **13** [`module-identity`](./13-module-identity/README.md) | `src/codegen/crossModule.zig` · `src/codegen/{erlang.zig,beam_asm.zig,runtime.zig}` — the **module-atom sites** for steps 1–6 (carve-out of 02 and 03), the two emitters **wholesale** for steps 7–20 · `modules/compiler-cli/src/cli/{build.zig,run.zig}` (the output layout, and `botopink run --target erlang`'s `-pa`) · the module-atom lines and `buildModule` signatures of `src/comptime/{template_eval,decorator_eval}.zig` (carve-out of 01) · the `tests/language/` cells for `is`, a named-type union `case` and decision 8 §7's printed form (coordinate with 12) | `snapshots/codegen/{erlang,beam}/`: **≈ 20** (half 1, names) then **188** (half 2, shapes) then **130** (half 3, value lines) | **opened 2026-09-18** in `.tasks/identity` (`fix/module-identity`), 14's steps 0–2 being the condition — scoped to **step 0 and half 1** (the four atom sites, which `fronts.md` calls a carve-out rather than a stop). **Halves 2–3 are held**: they own both emitters wholesale and re-record ≈318 cells in 02's and 03's directories, and both of those fronts have live work in their worktrees. Steps 17–19 additionally after 01's N19–N22. Merged from 1.0.4-beta's 16 and 19 |
| **14** [`comptime-on-beam`](./14-comptime-on-beam/README.md) | `src/comptime/{template_eval,decorator_eval}.zig` (unowned through 1.0.4-beta) · the eval-protocol half of `src/comptime/runtime/persistent_erl.zig` (carve-out of 08) · a new `src/comptime/runtime/prelude.zig` · the two `evaluate(…)` call sites and the memo cache of `src/comptime/infer.zig` (carve-out of 01) · `ComptimeModule` / `emitComptimeModule` in `src/codegen/erlang.zig` (carve-out of 02) and, for step 3, the untyped comptime mode of `src/codegen/beam_asm.zig` (carve-out of 03) · one new script in `scripts/` (carve-out of 11) | the 48 snapshots carrying `----- COMPTIME ERLANG` in `snapshots/{codegen,comptime}/**` | **steps 0–2 landed 2026-09-18** — merged into `feat` as `bef762b`, cold gate green: the erl side of erika-linq goes 1039 ms → **49 ms** (21×, acceptance was ≤ 60), N=200 emits **1 module and 875 bytes** where it emitted 200 and 2.8 MB. 33 `COMPTIME ERLANG` cells re-recorded, nothing else; `infer.zig` never touched. **Step 3 stays deferred**, now with its blocker measured: the *typed* beam backend already fails the case the untyped mode exists for |
| **15** [`language-surface`](./15-language-surface/README.md) | `modules/compiler-core/src/parser/types.zig` · `src/lexer.zig`, `src/lexer/token.zig` · `src/print.zig` and the `ParseErrorType` enum in `src/parser.zig` · four named sites in `src/parser/exprs.zig` — `parsePostfixChain` (`:845-877`), `parsePrimary`'s grouped arm (`:1221-1227`) and the two inlined block loops (`:162-179`, `:944-951`) — a carve-out of **01** · new cases in `src/parser/tests/**` (a carve-out of **07**) | — (step 4 is strictly accepting: no snapshot may re-record) | **landed 2026-09-18** — merged into `feat` as `109f6c9`, cold gate green, 19 new parser snapshots and **no existing snapshot re-recorded**. Held back deliberately: decision 29's parser half (uncommittable alone — see the decision), decision 36 (`patterns.zig` is 01's), module-level `var` (measured only) |
| **16** [`formatter`](./16-formatter/README.md) | `modules/compiler-core/src/format.zig` · `modules/compiler-core/src/format/**` · the member-trivia and member-order fields of `modules/compiler-core/src/ast.zig` and the sites that fill them in `src/parser/decls.zig` (`parseEnumItem`, `parseFieldList`, `parseMethodDecl`) — a carve-out of **01**. **Not** `src/parser/exprs.zig`'s two inlined block loops (G5), which are **15**'s | — (the formatter has no snapshot directory; its 239 tests carry their expected text inline) | **steps 3–5 landed 2026-09-18** — merged into `feat` as `37d3dc7`, cold gate green: the `default` keyword prints, nothing reorders, trailing trivia survives, and `assertLossless` fails 4 of 5 probes on the old formatter. **09's format step is unblocked.** Open: steps 1–2, and the printer arms 15 handed over |
| **17** [`beam-memory`](./17-beam-memory/README.md) | `modules/compiler-core/src/parser.zig`'s top-level declaration dispatch (`:436`, `:445-458`, `:531`) — **not** the `ParseErrorType` enum (`:61-158`, **15**'s) · the `ValDecl` struct in `src/ast.zig` (`:1891-1909`) · two diagnostics in `src/comptime/infer.zig` beside `:2742` (carve-out of **01**) · one emission function per backend: `commonJS.zig:438`+`buildValDecl` (**04**), `wat.zig:2104` `emitGlobalVal` (**05**), `erlang.zig:3205-3229` (**02**/**13**), the matching `beam_asm.zig` site (**03**/**13**) · a new `Form` variant in `src/codegen/beam/erl_ast.zig:252-266` and its `erl_emitter.zig` arm · new cases in `src/parser/tests/**` (carve-out of **07**). **Not** `libs/std/src/beam.bp` — specified by step 3b, landed by **09** | `snapshots/codegen/{commonJS,wasm}/**` — only cells step 2 makes legal; `snapshots/codegen/{erlang,beam}/**` only after 13 | not started — **every question answered 2026-09-18** (38–44, plus 48/49/50). Scope by decision 50: **steps 0–3b this milestone**, steps 4–8 a spec for after 13. Opens once 01 has **committed its step 4** (decision 49). Two carve-outs granted by name: `src/format.zig`'s `var` printer arm + one `assertLossless` case, in the same commit as the form (decision 48), and the two `infer.zig` diagnostics after 01's step 4. Decision 38's ecosystem cost is measured at **0** |

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
