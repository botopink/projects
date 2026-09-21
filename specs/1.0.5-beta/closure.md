# Closure — 1.0.5-beta

**Closed 2026-09-20**, at `botopink-lang` `feat` = `origin/feat` = `d55a3b87` (*Merge fix/checker: a
`case` arm resolves its pattern and its value, and exhaustiveness counts a domain*). The milestone was
decision 8's **run time**: the checker half the grammar had left untyped, the four backends as
file-disjoint fronts, the module atom and the type's identity in the value, the comptime evaluator off
`compile:file`, an audit of the written surface, the formatter's canonical form, and module-level `var`
with `@BeamMemory` behind it. Seventeen fronts, sixty-seven decisions.

**Where the open work went:** [`specs/1.0.10-beta/00-compiler-carry-over/`](../1.0.10-beta/00-compiler-carry-over/README.md)
— every open and in-progress item, ranked, with the deep dives that still apply copied beside it.
[`decisions-taken.md`](./decisions-taken.md) **stays here** as the record; the carry-over references it
by path.

**How this record was derived.** Not from memory: the maintainer's status column in
[`fronts.md`](./fronts.md) (rows 22–38), the commit subjects and merge bodies of `botopink-lang`
between `c2dd780` and `d55a3b87`, `tests/language/expected-failures.txt` at `d55a3b87` (58 lines, each
naming the row that makes it pass), the six `.tasks/*` worktrees (`git status`, `git diff`, `todo.md`),
and the decision sections themselves. Where none of those says, the row below says **unverified** and
names what would verify it.

---

## What the milestone measured, at its close

| | Reading | Source |
|---|---|---|
| `tests/language/run.sh` | **324 passed / 48 expected / 0 failed** — from 270 / 64 before front 01's steps 4–5, and 205 / 54 at the milestone's open | merge body of `d55a3b87`; the file's header |
| `run.sh --target beam` | **24 / 18 / 0** — beam executes (`erlc +from_asm` + `erl -noshell`); it is not in `--target all` until policy 3 moves the `.S` layout | decision 8; `eeff1e15` (12 step 3) |
| `expected-failures.txt` | **58 lines** (48 under `--target all`, 10 beam-only): 01 · 23, 02 · 12, 03 · 9, 05 · 6, 04 · 5, 13 · 3. Front 12 owns none, by design | the file at `d55a3b87`, recounted with its own command |
| `snapshots/comptime/**` | **1079 → 338** files at `579ab0d` (one per test, not four per slug); 340 today — decision 58's two error cells | 06's merge `78394197`; `ls` |
| `snapshots/codegen/wasm/**` | 314 → **328** | 05's merges `1b65ffda`, `f2ba518e` |
| `scripts/beam_export_audit.sh` | **319 / 319** — every emitted `.S` assembles | 03's merge `38c35d1a` |
| `format --check` | all five libraries clean at decision 61's layout — **607 lines** moved across six trees, to the line 16 predicted; **no gate calls it** | 09's merge `8ed3757e`; decision 66 |
| erika-linq comptime | erl side **1 039 ms → 49 ms** (21×); N=200 call sites emit **1** module and 875 bytes where they emitted 200 and 2.8 MB | 14's merge `bef762be` |
| Gate | `scripts/gate.sh --cold` green on every merge into `feat`, through the pre-commit hook; no `--no-verify` | the merge bodies |

Not re-run at close: `zig build test-libs` (09 step 1 recorded 11 passed / 0 failed / 1 skipped after
the reformat; 13's `todo.md` records a different baseline shape — re-measure before quoting either).

---

## Fronts

Status: **done** — every step landed or struck with a reason · **partial** — steps landed, named steps
open · **open** — never started. Hashes are `botopink-lang` commits unless a sibling is named.

| Front | Status | What landed (evidence) | What did not, and where it went |
|---|---|---|---|
| [`01-checker`](./01-checker/README.md) | **partial** | Steps 1–3 (`cf89d21c` `unknown`, `81e11eb3` unions, `db9a5b50` `is` and narrowing); steps 4 a–c and 5 (`f181ec42`, merge `d55a3b87`: arm resolution, exhaustiveness as a `CaseDomain` walk — 13 expected-failure lines deleted, 17 by the front in all); step 8 R3 (`e37186bb`, decision 15); step 11's `Display` (`49f97b4a`, decision 27); decision 37 (`af1a97f5`, a record is immutable); decision 58 (`ef6bb699`, inline `implement` verified); decision 62's `Type.assoc()` return type (`d55a3b87`) | Steps 6 (generics §1.1/§1.2), 7 (trailing defaults), 8 R1/R2/R4–R9, 9 (`.withLoc` sweep — 135 error snapshots, "land last"), 10 (parser gaps: `if (a && b)`, `_` binder, decisions 11/12), the rest of 11 (`Self<…>` ×16, five `= []` bindings, `Dict implements Display`), step 4 (d) sections; decision 63's amendment (the `xs[k]` → `xs.at(k)` rewrite in `transform.zig`); decision 54's `null` arm (does not parse); decisions 44, 45, 47, 57, 31, 9 — decided, no landing recorded; `curried_call.bp` typing (handover 15). → C-02, C-04, C-08, C-09, C-14, C-15, C-18, C-21 |
| [`02-erlang`](./02-erlang/README.md) | **partial** | Steps 5 and 6 (`a9e9d03c` condition-loop value, `f547f99f` generator protocol — the milestone's only run-time crash, merge `27fd6eac`); step 3's arms (`e4722e6e`) and `patternNode`'s three defects (`fe87db51`, merge `a48c06b3`: 20 of 20 `case` cells); the imported-enum method (`32dc984e`); decision 30's index (`c2b4c8e6`); decision 62's `Shape.unit()` (`7dd01a60`); the prelude-parse memo 14 asked for (`9e1a1c43`); step 4 measured as not reproducing | Step 1 F1 (`, ` separator) and F2–F4 (record/variant/`Display` text = 13 step 18); step 2 D1–D3 (`is` by value, `unknown`, §2.3 `==`) — unverified, no commit names them; step 3's `1...9` arm (`{'', 1, 9}`, one line from fixed); step 7 (contested: the merge says it does not reproduce, the line `test/string_case_conversion.bp` still stands); steps 8, 9 (behind 01 R6/R7); decision 52 (`null`, prints `3`); decision 55's four lines ("no step"); decision 64's wrapper. → C-01, C-03, C-06, C-07, C-09 |
| [`03-beam`](./03-beam/README.md) | **partial** | Step 2 F0/F1/F5 (`416c9793`, 163 cells gain a RUN LOG); step 3 D5 (`5ce61da3`, closed by running), D6 (`b09cf0c4`), D7 (`841e25d4`, `{invalid_store,{y,0}}` — no snapshot could see it); step 4 (`448b9350`, `35e91b12`); step 5 as docs (`698d022c`: 8 `make_fun3` sites, 0 a block as a value); decision 30's index (`3d6517fc`); an unlowered builtin aborts instead of answering (`5ce61da3`, `17503656`); `Shape.unit()` (`7dd01a60`). Audit 319/319 | **BR5 (step 1) struck from 1.0.5 by decision 62** — structural block (nothing parses Erlang), cost re-measured 50.6×, `wip/br5-beam-templates` parked; step 2 F2–F4 (13 step 18); step 3 D1–D3 — unverified; D4's tuple/`..`/type patterns (`beam_asm.zig` reads neither `PatternShape` nor `Pattern.rest`) and `1...9`; decisions 52/55 lines; decision 62's beam `.length` on an index receiver (silent, exit 0); `run/index_expression.bp` line. → C-01, C-02, C-06, C-07, C-24 |
| [`04-js`](./04-js/README.md) | **partial** (mostly done) | Decision 5 (`794551c1`, class per declaration, subclass per variant); step 1 F1/F5 (`c2539653`); step 2 D1 (`e09a09bc`), D4 (`6196b866`); step 3 (`7b6b5d37`); step 4 (`17c5f8b5`, decision 35); step 5 (`64fa2d72`); step 6 T1–T3 (`d20ac688`, `37efbd4e`); the three `case` defects (`f1757f41`); index (`17e20592`); the loose optional guard (`b5d63ac7`); step 8 classified (`1b86bc38`: 1 site of 10). Merges `4841983c`, `13796590`. F2–F4 pass on commonJS already | Step 7 (pattern as binding target, behind 01 R5); step 8's one dead site (behind R7); `d["k"]` (46 → 63's amendment); decision 55's four lines; step 2 D2/D3, the `tsc --noEmit` gate (no `tsc` in the checkout) and `42.toString()` — unverified. → C-02, C-06, C-09, C-18 |
| [`05-wasm`](./05-wasm/README.md) | **partial** (mostly done) | Steps 1–8 (merges `1b65ffda`, `f2ba518e`, 13 + commits): F1 (`bbb3ca00`), F5 (`6a1eaa23`), step 3's real cause — two `?T` writer/reader disagreements (`067f62e0`), steps 4–5 (`b40169bf`), step 6 (`bbdc1805`), step 7 implemented not deferred (`9c8d8dbc`), step 8 struck (0 reachable sites), decision 30 including the nested read (`3281f4c9`, `91b1553f`), decision 52 (`13688675`, `0bc8051d`), a record traps instead of printing its address (`8639ef7d`) | F2–F4 (13 step 18, behind the trap); step 2 D1–D3 — unverified; D4's `1...9` and decision 55's two lines — **in `.tasks/wasm`, uncommitted**; decision 22 makes the box 13's design. → C-01, C-06, C-07 |
| [`06-comptime-dedup`](./06-comptime-dedup/README.md) | **done** | Merge `78394197` (`579ab0d0` one snapshot per test, `b21373a3` inferred types rendered, `2ee2e24e` the `id` field removed, the skipped declarations serialised, `ident` spelled). `fronts.md`'s open question is answered: `grep -rl '"id": 0' snapshots/comptime` → 0 | Three handovers, all still on disk: `snap_audit.sh:501` dead arm (07), `comptime.zig` `type_ids` five sites (01), `infer_decls.zig:143` misnamed test (07). → C-22 |
| [`07-review-backlog`](./07-review-backlog/README.md) | **open** | Nothing — no commit names a 07 step; its wave-B precondition (06 step 2) is met, wave A's is half met (04/05 closed, 02/03 open) | Waves A and B, steps 3–5, plus 06's and 08's handovers. → C-22 |
| [`08-hygiene`](./08-hygiene/README.md) | **partial** | Steps 1–5 (merge `6df4eed2`): `docs.md`'s "decided, not implemented" table 12 → 5 rows (`7fa248f2`, `47bd36c6`, `85cdd456`), the `libs/std` known-red table deleted (`e07718ad`), 5 of 19 `primitives.d.bp` comments (`21d33c85`), the transport error's two readers named (`2dcfde67`), steps 1 and 4 needing no edit | 2.1's 14 remaining comments (11 in `erlang.zig`), 3.1's `@external(` comments (18 in `erlang.zig`), step 6's five sites in 07's files. → C-23 |
| [`09-ecosystem-residuals`](./09-ecosystem-residuals/README.md) | **partial** | Step 1 (emilia `3e7ab05`, erika `02f4344`, jhonstart `78e01ca`, rakun `6567b14`; then decision 61's layout — erika `054efdd`, jhonstart `13d1672`, onze `e1aee41`, rakun `f1fa846`, `libs/std` `652b624c`/`68093afc`, merge `8ed3757e`); step 2 superseded by decision 17; `std/beam` layer 1 (`dc272aae`, decision 43, no `.zig`) | Step 3 (decision 8 in the five libraries — after 01 N28); step 4 (erlang cells after 13); step 5 partial (erika/jhonstart/onze `AGENTS.md`); decision 63's four `libs/std` rows — **in `.tasks/ecosystem`, uncommitted**; decision 66's gate caller; `beam.bp`'s three stale spellings (decision 43's correction). → C-02, C-11, C-14, C-17 |
| [`10-cli-residuals`](./10-cli-residuals/README.md) | **done** | Merge `d5e14ade`: steps 1–3 already in `feat` (`ccc0ab17`, `7207f4f4`, `315a38fe`), each re-verified by a probe; step 4 measured the erlang runner's real shape (`8babfa59`) → 13 half 1, decision 56 | `stash@{0}` (front 20 defect A) read and left as an obsolete subset of `feat` — drop it; decision 66's `reject/**` arm in `format_cmd.zig` is a new row of this front's file. → C-11, C-25 |
| [`11-tooling`](./11-tooling/README.md) | **partial** | Steps 1–4 (vscode-extension `94c1366`, `e553aa6`; `ae6476c`; `9589971` + `43eabe5`, decision 7); `optional<T>` written into the user's file by a code action (`3c5e8777`, 4 new / 0 re-recorded); `??` painted as two optional markers (vscode-extension `dd46d1f`). `npm test` 43/0 | Step 5 (the `record { … }` name in `completion_decorator_record.snap.md`) — **in `.tasks/tooling`, uncommitted**, one snapshot line. → C-19 |
| [`12-language-tests`](./12-language-tests/README.md) | **partial** (mostly done) | Step 1 (`7ab6a55e`); step 2 as a running process (`fcc4b5b5`, `b728d912`, `fe871ed4`); step 3 beam executes (`eeff1e15`); step 4.1 identity cells (`7b96ce7d`); cells for decisions 28/30/33 (`5dfb6385`) and 52–55 (`6a9d404d`); "compiles, and these tests fail" with an escape for `\|` (`599625a1`, merge `c66a1593`); step 5 (`7bfecf7f`) | Steps 4.2–4.4 (local-dependency `modules/` cell, `@panic`/`@todo`, no-external-target) — unverified; decision 59 (b)'s `run.sh` tally; cells for 63–66; `index_an_index_past_the_end_answers_zero` rewritten a third time; the three `modules/*` cells decision 66 hands over. → C-16 |
| [`13-module-identity`](./13-module-identity/README.md) | **partial** | **Half 1** (`154f3bc9`, merge `b09bf9c6`): `ModuleId`/`erlAtom`/`erlDeclAtom` with a collision check, `out/erl/` and `out/beam/` (decision 6), the harness and audit follow the atom, the collision fixtures, comptime modules in the same shape, `run --target erlang` reaching every module (`erlc -o` + `erl -pa`, which also closed half 2's step 7 and 02's three `modules/*` lines); `Shape.unit()` (`7dd01a60`) | **Halves 2 and 3** (steps 8–19): policy 3 — one BEAM module per `type` and `behavior` (decision 23: `__b__` reserved, nothing emitted); the type's atom in the value as decision 21's **T2** tagged tuple (354 cell-writes over 210 files); `is`/union `case`/§7 print on named types (steps 17–18, also what 02/03/05's F2–F4 wait for); the JS unit variant (step 19, optional). Decision 22 makes wasm's box this front's. `.tasks/identity` (`fix/identity-halves`) holds **decision 64's wrapper**, not halves 2–3. Step 6's residuals (bare-name `CrossModule.exports` collision; the comptime server never purges) are in no pending list. → C-01, C-03, C-25 |
| [`14-comptime-on-beam`](./14-comptime-on-beam/README.md) | **partial** | Steps 0–2 (`f0ec3519`, `75d4ede2`, `bee9b85a`, `19a3b01c`; merge `bef762be`): 21× on erika-linq, one module per declaration, 33 `COMPTIME ERLANG` cells re-recorded, `infer.zig` untouched. Two acceptance numbers not met (N=200 build 2 172 ms, 9.4 ms per evaluation) — the cause was `emitErlangModule` re-parsing the preludes, since fixed by 02's `9e1a1c43` | Step 3 (the module reaches the node as `.S`) — deferred until after 13 by decision 62, still happens by decision 24; blocker measured: `beam_asm.zig` has 0 untyped sites and the typed backend already dies `{unresolved_method, toUpper, 1}` on the case the untyped mode serves; prize ≈ 39 ms of 645. → C-20 |
| [`15-language-surface`](./15-language-surface/README.md) | **done** — with three deliberate hold-backs | Merge `109f6c97` (8 commits, 19 new parser snapshots, 0 re-recorded): `T[]` at the exit, the chain from every receiver, `42.toString()`, `parseBlockBody`, decision 30's index and slice, decision 28's `??`, decision 33's bodyless `fn`; the catch-all names the token it stopped on (`e83c783`). Decisions 28, 30, 33 came out of it | Decision 29's parser half — written, uncommittable alone (rejects `libs/std`'s prelude), parked as [`decision-29-parser-half.patch`](./15-language-surface/decision-29-parser-half.patch), re-ordered by decision 60; module-level `var`'s grammar (→ 17); the trailing lambda's one-line body (`arrow_when_empty` — why `botopink format` refuses three `examples/jhonstart-app` files); `xs[0] = 5` (a decision-37 question). → C-05, C-11, C-13 |
| [`16-formatter`](./16-formatter/README.md) | **partial** | Steps 1–7 (merges `3cfb65cb`, `37d3dc77`, `fc57d434`): the `default` keyword prints (`098a4932`), member order and trailing trivia recorded and printed (`fed06ac9`, `b0cdf94f`), `assertLossless` (`a23ae797`, failed 4 of 5 probes on the old formatter), 15's printer arms (`1471cfca`, `fd7abb94`, `2c72da8c` — three forms had round-tripped into different programs), decision 61's four rules (`c0eb82f4`, `7a25bee9`, `8183b29e`, `2407d4af`), the `var` arm assembled from parts (`4aea72a1`) | Decision 65 (`fits` stops at the first `concat`; every group renders flat) — **in `.tasks/formatter`, uncommitted**, both commits started; the recorded comment column (rakun `runtime.bp:13`); the residual layout rows of step 6 (not enumerated — unverified); rule 3 at `arrow_when_empty` (15's parser); decision 29/60's `;` (printer half); the labelled tuple after 01 types it. → C-12, C-13 |
| [`17-beam-memory`](./17-beam-memory/README.md) | **partial** (in progress) | Every question answered (38–44, 48–51, 64); step 3b's `libs/std/src/beam.bp` landed by 09 (`dc272aae`); the formatter's `var` arm prepared (`4aea72a1`); decision 49's condition met at `d55a3b87` | Steps 0–3 (the `var` carrier, `val` assignment refused, commonJS/wasm emission, `@BeamMemory` validation) — **in `.tasks/beammem`, uncommitted**, +382 lines with parser/format/infer tests, no run verification, no gate; step 3b's third acceptance bullet blocked by decision 64; steps 4–8 a spec for after 13 by decision 50. → C-03, C-05, C-10 |

---

## The `.tasks/*` worktrees

All six were worktrees of `repository/botopink-lang`, all at `d55a3b87` = `feat` = `origin/feat`,
**zero commits ahead**, what each held uncommitted, none gated — the state at the close, kept below
as written. **Later the same day** three of them were landed on `feat` as-is and removed:
`formatter` (`wip(formatter)` `74b6ce8b` + merge `f9cf2ace`), `tooling` (`f952bfc6` + `11b9a157`),
`wasm` (`8594e4ba` + `56369e55`), gate green at the tip, pushed as `origin/feat` `56369e55`; their
acceptance rows are still open in `specs/1.0.10-beta/status.md` (C-06, C-12). `beammem`, `ecosystem`
and `identity` remain with their changes staged and the pre-commit gate red (`typeToString` missing
at `infer.zig:2870`; 8 and 7 snapshot mismatches). The meta submodule pointer still names `d55a3b87`. The branch names are
not the `fix/<front>` names the fronts opened with — each is a follow-up row.

| Worktree | Branch | Uncommitted | What it is | What has to happen |
|---|---|---|---|---|
| `.tasks/beammem` | `fix/beam-memory` | 11 files, +382 −12 (`parser.zig`, `decls.zig`, `ast.zig`, `infer.zig`, `env.zig`, `format.zig`, `commonJS.zig`, `wat.zig`, 3 test files); `todo.md` steps 0–3 all unticked | Front 17 steps 1–3 essentially complete in code and unit tests: `var` parses at module level, annotations on a `ValDecl` with recorded argument labels, `refuseValAssign`, `validateMemoryAnnotations` with decision 41's texts, the `var` printer arm, `let` on commonJS, `.mutable` on wasm | **Continue in 1.0.10 (C-05).** Before commit: step 2's run verification (prints `2` on node and wasmtime), `AGENTS.md`, the migration count in the message, `gate.sh --cold`; recount the header if a line goes |
| `.tasks/ecosystem` | `fix/index-behaviors` | 16 files, +183 −78 (`builtins.d.bp`, `dict.bp`, `primitives.bp`, `libs/std/AGENTS.md`, `js_prelude.zig`, `erlang.zig` 4 lines, `wat.zig` 12, tests, `AGENTS.md`s, `stdlib-tour`, `std_import` cell); no `todo.md` | Decision 63's amendment, the `libs/std` half: `behavior Index<K, V>` / `Slice<V>` ambient in `builtins.d.bp`, `Dict` `implement Index<K, V>` with `lookup` → `at`, `charAt` → `at`, the prelude helpers renamed. Not the `transform.zig` rewrite (01's) | **Continue in 1.0.10 (C-02).** It cannot be verified alone — `xs[0]` still types as `void` until the rewrite lands; land the two halves together or the rename first as a pure rename with its ≈83 snapshots classified |
| `.tasks/formatter` | `fix/fits` | 3 files, +367 −19 (`format.zig`, `format/tests/expressions.zig`, `format/AGENTS.md`); `todo.md` two commits, all boxes unticked | Decision 65: `fits` measuring through `concat`/`nest`/`group`, and the method-chain construct already documented in `AGENTS.md` — so both of the two planned commits are in one tree | **Continue in 1.0.10 (C-12).** Split as the `todo.md` says: commit 1 byte-identical (every group pinned, the six trees diffed), commit 2 the chain — 09 reformats after |
| `.tasks/identity` | `fix/identity-halves` | 2 files, +34 −9 (`erlang.zig`, `beam_asm.zig`); `todo.md` is half 1's, stale | **Decision 64**, not halves 2–3: `externalWrapperNeeded(f)` no longer asks the bare-import route, so a qualified std host call (`erlang.self()`) gets its wrapper and export; the beam twin `hostDeclareWrapperNeeded` is declared and **not wired**. No tests, no re-records | **Continue in 1.0.10 (C-03, then C-01).** Wire the beam site, add the fixture 17 step 3b names (run under `erl`), re-spell `beam.bp`'s header; then halves 2–3 start at step 8 |
| `.tasks/tooling` | `fix/tooling-step5` | 2 files, +39 −42 (`infer.zig` the three declaration-name builders; one LSP snapshot line) | Front 11 step 5: `buildRecordDeclName`/`buildInterfaceDeclName`/`buildEnumDeclName` spell the 1.0.3 surface; `completion_decorator_record.snap.md` re-recorded — the one line `fronts.md` predicted | **Land at 1.0.10's opening (C-19)**: gate, `AGENTS.md`, strike 07 step 3's row, merge |
| `.tasks/wasm` | `fix/wasm-patterns` | 11 files, +82 −16 (`wat.zig`, tests, 6 snapshots, `wat/AGENTS.md`, `expected-failures.txt` −3) | Decisions 53 and 55 on wasm: the `A...B` range pattern arm (was falling into the variant path and answering `0`), a value `break` ends a collection loop; three lines deleted, six RUN LOGs move | **Finish and merge (C-06's wasm half)**: verify the six RUN LOGs by running under wasmtime, recount the header from the file (decision 59), gate, merge |
| — | `wip/br5-beam-templates` | a stash converted to a branch on `440a1d3e` (2026-09-17): an 836-line Zig Erlang lexer+parser that no longer builds | Front 03's BR5, struck from 1.0.5 by decision 62 | Keep parked until BR5's own spec is written (C-24); then delete or restart from it |

`fix/module-identity` (half 1's branch) is gone locally; its work is in `feat`. `.tasks/cli`'s
`stash@{0}` from front 10 is still in the main checkout's stash list and is safe to drop.

---

## The decision record

Sixty-seven decisions in [`decisions-taken.md`](./decisions-taken.md); none pending (65 was the last,
answered 2026-09-19; the next number is 68). Status as the record and the tree state it:

**Implemented** — 6 (flat `out/erl/`, `out/beam/`) · 8 (beam executes in the suite) · 15 (lower-case
`#[@external]` is a located error) · 16 (the `mod` path warning fixed at its cause, converged on the
option it refused) · 19 (the renderer's `id` removed) · 27 (`Display` ambient, in `libs/std`) · 28 (five
forms, all parse — except module-level `var`'s grammar, which 17 carries) · 30 in the parser and all four
lowerings · 33 (bodyless `fn` declares `-> void`) · 34 (no `format --check` exemption — nothing to build)
· 35 on commonJS (`__bp_eq`) · 37 (a record is immutable) · 53 as an amendment (the compiler did not
move; the `1...9` defect survives) · 56 (`erl`'s exit status, with the runner) · 58 (inline `implement`
verified) · 61 (the four layout rules, 607 lines) · 62 (the schedule, and its three defects: two landed,
the beam `.length` one open) · 5 (a JS value is a class per declaration, a subclass per variant).

**Partially implemented** — 3 (the unresolved-import error is in `feat`; the shorthand resolves on
commonJS via 04 step 5; the `docs.md` cell is not evidenced) · 8's run time: complete on commonJS
except decision 55, on wasm except F2–F4 and decision 55 (uncommitted), on erlang and beam **behind
13** for `is`/unions/F2–F4 and open for 52/55 · 24 (steps 0–2 of 14; step 3 deferred, still owed) · 26
(the checker unions arms; the boxed value that carries it on erlang/beam/wasm is 13's) · 29/60 (the
parser half written and parked; the optional-`;` landing not made) · 43 (layer 1 landed; layer 2's
route is 64) · 46 (answered, then dissolved into 63's amendment: the route *is* the `at` call) · 50
(3b's module landed; 0–3 in `.tasks/beammem`; 4–8 a spec) · 55 (cells landed; wasm in `.tasks/wasm`;
commonJS, erlang, beam still run the loop on) · 63 (the `libs/std` half in `.tasks/ecosystem`; the
`transform.zig` rewrite, the `docs.md` paragraph and the beam `.length` row open) · 64 (erlang side in
`.tasks/identity`; beam helper unwired).

**Decided, not landed** — 1, 2, 10, 25, 32 (document corrections: `@AsyncIterator`, `?T` only, the
`@code` rename, `is` does not bind, no `Option.Some` value names — the record is silent on the edits) ·
7 as a sweep is done, the row stands as landed · 9 (`Array.unique` in `libs/std`) · 11, 12 (delete
`<Pattern> as <name>`; reject unnamed payloads — 01 step 10) · 13 (C1/C8 as 01 steps) · 17 (rakun on
every target — larger than a residual; its first row is 17's `var`) · 21, 22, 23 (T2, the box on every
backend, `__b__` — all 13's halves 2–3) · 31 (`any` still parses and checks) · 36 → 53 (nothing to make)
· 38, 39, 40, 41, 42, 48, 51 (17; 38/41/48/51 in the uncommitted diff, 39/40/42 in steps 4–8) · 44, 45,
47, 57 (01 rows with no step) · 52 on erlang (`3`) and beam (`ok`) · 54 (the decided spelling does not
parse) · 65 (in `.tasks/formatter`) · 66 (no gate calls `format --check`; 14 of 27 project directories
red over 18 files, behind two parse defects).

**Superseded or amended** — 4 by 62 (and 62's first call moot: 06 had landed) · 14 by 28 · 18 by 34 · 20
and 36 by 53 · 46 by 63's amendment · 63 (original) by its own amendment · 2's pattern half by 54.

**Principles, not rows** — 4's surviving order (14 → 13 → backends), 24, 34, 35, 49, 50, 59, 60, 61's
"a rule that changes how every library looks is the maintainer's", 62, 65's four rules, 66's structural
exemption, 67 — carried forward below.

---

## Rules carried forward

Earned here or re-confirmed here, and still binding on the carry-over and on every front that opens
after it:

- **Decision 67 — the most restrictive behaviour, and no configuration that bypasses it.** Every
  option list is written and chosen against it: the stricter side by default; an exemption is
  *structural* (a directory the tool recognises by what it is, like `tests/language/reject/**`) and
  never a knob, a skip list, a pragma or an environment variable. "Keep the strict behaviour and add a
  flag for the people it inconveniences" is not an answer.
- **Decision 4 / 62 — the order.** `14` before `13`, `13` before the backends read the identity; 13's
  halves 2–3 run *now*; 14's step 3 after 13; nothing is sequenced behind 06 any more. Decision 62 is
  read as the schedule wherever `fronts.md`'s Order section differs.
- **Decision 24 — the principle governs, not the build time.** No Erlang source in the compile path;
  every step of 14 happens, deferred is not struck.
- **Decision 59 — whoever deletes an `expected-failures.txt` line recounts its header from the file**,
  with the file's own command, never from their own delta.
- **Decision 60 — the parser widens before the printer narrows.** A form the formatter is to stop
  printing is first accepted as optional by the parser, as its own landing.
- **Decision 61 / 65 — canonical layout is the maintainer's call, one construct at a time**, all-or-
  nothing per group, `+4` continuation, the output a pure function of the file's content (no
  "preserve what the author wrote", ever), and the canonical form written down *before* it is turned on.
- **Decision 63 (amended) — the core stays generic.** An index expression has no typing rule of its
  own: it rewrites to a method call, and indexability comes from an ambient behavior, so a library's
  own type becomes indexable with no compiler change.
- **Decision 43 / 64 — no line of `.zig` names a host facility.** ETS, `persistent_term`, the process
  dictionary and every host call live in a target-specific std module; emitting host calls from `.zig`
  is the bypass 67 forbids.
- **Decision 46 — what inference never recorded, each backend answers its own way** — named as the
  pattern to refuse: the checker records the receiver, the backends route.
- **Decision 55 — four backends agreeing is not four backends being right.** A shared accumulator was
  the agreement; the decision overrode it.
- **Decision 21 — a re-measured cost is not a new argument.** The maintainer's call is the shape.
- **Decision 37 / 38 / 35 — `val` means what it reads as.** A record is immutable, a `val` is
  immutable (the error names `var`), and structural equality follows from that rather than being
  legislated.
- **Decision 34 / 66 — `format --check` has no exemption mechanism and looks at the whole project**,
  and a widened scan that nothing invokes is a wider silence: a gate must call it.
- **Decision 26 — inference may produce a union type**; a `case` whose arms disagree is not an error.
- And the milestone's own working rules, unchanged: a front never edits a file it does not own (it
  stops and reports; carve-outs are named and granted); a re-recorded snapshot is classified, not
  bulk-accepted — a changed RUN LOG is a value explained from the emitted code or verified by running;
  a refactor front lands byte-identical; one commit never carries two reasons; the gate is
  `scripts/gate.sh --cold` in the worktree and again after the merge, never `--no-verify`; `AGENTS.md`
  of every directory touched, in the same commit; a claim in a spec is measured or marked unverified.

---

## Unverified at close

Things this record could not settle from the sources, and what would settle each:

| Claim | How to verify |
|---|---|
| 02 step 2 D1–D3, 03 step 3 D1–D3, 04 step 2 D2/D3, 05 step 2 D1–D3 (`is` by value, `unknown` stores nothing, §2.3 `==`) — no commit subject names them; `fronts.md` counts 05's "steps 1–8 closed" | run the §4/§2/§11 cells of `tests/language/` on each backend; the `type_identity_*` lines that stand say the named-type half waits on 13 |
| 02 step 7 — the merge says `toUpperCase`/`toLowerCase` do not reproduce; `test/string_case_conversion.bp` still has an erlang line | run the cell on erlang; delete the line or the claim |
| 12 steps 4.2–4.4 — no commit, no README sentence | `ls tests/language/modules/`, look for a `@panic`/`@todo` cell and a no-external-target cell |
| 16's four residual step-6 layout rows — `fronts.md` counts them, nothing enumerates them | diff 09's 861-line reformat against decision 61's four rules |
| 04's `tsc --noEmit` gate and `42.toString()` on node | install `tsc`; run `run/` cells on node |
| 06's `id` field (fronts.md's open question) — **settled**: `2ee2e24e`, 0 hits | — |
| 13 step 6's residuals "as a row in `fronts.md` § Unowned items" — the box is ticked, no row exists in either decisions file | they are carried as C-25 |
| `zig build test-libs` at close | run it from a cold cache in the main checkout |
