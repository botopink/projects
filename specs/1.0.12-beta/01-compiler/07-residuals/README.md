# Front 07 — residuals: the snapshot review, the documents and comments, the ecosystem's tail

**Priority:** low · **State:** partial: steps 3, 5, 6, 7, 12, 13 done (08's items 1–2 done by their
owners, 09's item 1 and 25's steps 2–3 done elsewhere); steps 1, 2, 4, 8–11 open
**Depends on:** `02-erlang`, `03-beam`, `04-js`, `05-wasm` landed (steps 1, 4 re-derive/rename in
their snapshot dirs) · `01-checker` landed (step 2) · `16-formatter` steps 1–2 (step 10) · maintainer
on C-14 (step 9) · every library track merged into its own `feat` (step 11, last) ·
`18-comptime-runtimes` step 4 (transport test, its own)
**Owns:** snapshot review — `modules/compiler-core/src/utils/snap.zig` (18 owns directory
selection) · `scripts/snap_audit.sh` and its `scripts/AGENTS.md` section · `src/codegen/tests/**`
(a backend front's fixtures are its carve-out while it runs) · `src/comptime/tests/**` except
`helpers.zig` · `src/parser/tests/**` · `modules/language-server/src/tests/**` · per-report status
lines in `specs/1.0.1-beta/06-snapshot-review/` · snapshot **renames** only (`git mv`,
byte-identical) — documents: `repository/botopink-lang/docs.md` prose (with 23, 24; 114 owns marker
and fence lines), `README.md`, `examples/**`, `libs/std/botopink.json`, `libs/std/AGENTS.md` (with
23), relative links of `specs/` · [`beam-memory-docs-text.md`](./beam-memory-docs-text.md) ·
comments in other fronts' files, only after their owners — ecosystem: `repository/erika/**` (with
`02-std-and-packaging/98`, owner of `erika/modules/erika-test/**`, `examples/erika-linq/README.md`,
`erika/AGENTS.md`) · meta submodule pointers
**Does not touch:** any lowering (02–05), checker and parser sources (01), `comptime/snapshot.zig`,
`codegen/snapshot.zig` (18), `libs/std/src/**` (std track), `modules/language-server/src/**` outside
`src/tests/` (26), the other four library trees, `c13-migrate.py` (16's — run, not edited). A
`wrong-output` row needing one of these is **registered** in the owning front's README with its
snapshot name, never fixed here.

Paths: steps 1–5 relative to `repository/botopink-lang/modules/compiler-core/` (those starting
`scripts/` or `modules/` to `repository/botopink-lang/`); step 6 on, to `repository/botopink-lang/`.
Report citations (`codegen-features.md:85`) = lines in the 1.0.1-beta review reports.

## Goal

Every snapshot proves its test's claim (1.0.1-beta review's open rows re-derived, closed); no
comment/document teaches a retired form; `docs.md` has the `@BeamMemory` text; erika migrated and
reformatted; submodule pointers bumped in one sweep.

## Mechanism

- **Orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points, test
  helpers carry `@src()` into the trace, `scripts/snap_audit.sh --mode=orphans`.
- **Review worksheet.** `scripts/snap_audit.sh --mode=review`: one TSV row per unique snapshot, test
  `file:line`, verdict seeded from the reports by header cell.
- **Snapshot layout.** `snapshots/codegen/<runtime>/<target>/` per comptime runtime (`beam`, `wat`),
  equal by `--mode=runtime-parity`; `snapshots/comptime/{ast,errors,runtime,templates}/`;
  `snapshots/parser/`; `modules/language-server/snapshots/lsp/`. A test rename in
  `src/codegen/tests/**` moves one file per target per runtime tree; elsewhere one.
- **Reports.** Each has a `**Status (1.0.1-beta close)**` block (re-derive every row at HEAD) — not
  the status line steps 1–2 append. Never trust a cited line. 3.11 `parser.md`, 3.12 `lsp.md`
  closed; 3.3, 3.6 worked.

| Batch | Report | Open rows (1.0.2-beta re-derivation) | Wave |
|---|---|---|---|
| 3.1 | `codegen-features.md` | 168 | A |
| 3.2 | `codegen-control_flow.md` | 87 | A |
| 3.4 | `codegen-values-dispatch-externals.md` | 99 | A |
| 3.5 | `codegen-builtins-aggregates.md` | 66 | A |
| 3.3 | `codegen-wat-narrowing.md` | worked; `:70` left | A |
| 3.6 | `codegen-comptime-misc.md` | worked; registered rows close with their fronts | — |
| 3.7 | `comptime-errors-effects.md` | 48 | B |
| 3.8 | `comptime-decls-variants.md` | 59 | B |
| 3.9 | `comptime-templates-types-exprs.md` | 40 | B |
| 3.10 | `comptime-generics-effects-decorators.md` | 78 | B |

## Done

08 item 1 `primitives.d.bp` swept from `erlang.zig` (02 step 11) and `comptime/` (01 step 14) · 08
item 2 owners' `@external(` sweeps (01 step 14, 02 step 11) · 09 item 1 erika-linq `"targets"`
lifted, ledger deleted (00-gate/113) · 25 step 2 hooks in worktrees: meta `scripts/worktree-add.sh`,
meta `AGENTS.md` § Worktrees (00-gate/115) · 25 step 3 gate re-timed: 12m16s → ~7m30s cold
(00-gate/115, 133; decision 265) · step 3 the `uncertain` rows: every remaining row answered in its
report's 1.0.12-beta status line (`assert_with_message`, `assert_pattern_with_enum_variant`,
`case_nested_case_in_block_arm`'s semantics half, S15, S16, `operators_equality_maps_to`,
`external_a3_result_template_owned_declare_fn`, `path_access_with_bad_tail_raises_focused_error`,
`generic_enum_result_t_with_ok_and_err`), each re-derived at `feat` · step 5 the test comments:
the listed sites plus every stale `KNOWN` / known-wrong note in `src/codegen/tests/**` re-measured
against the four RUN LOGs (aggregates, builtins, comptime, dispatch, externals, features,
narrowing, std_package, wat, beam; single-backend cells run with `botopink run` on the other three)
and rewritten; LSP `hover.zig:304`, `diagnostics.zig`'s D10 note and test name · step 6
`docs.md` § Bindings part 1, § `@BeamMemory` part 2 (a `project` fence with an erlang manifest —
`check` reads the manifest's target; the unverifiable "`val` shorthands" sentence left out, the
`PersistentTerm` hint sentence matched to the compiler's hint) · step 7 no fence spells
`Option.Some`/`None`, `AsyncIterator`, old `@code` or a binding `is` (the `Opt { Some, None }`
type-application example renamed `Slot { Full, Empty }`), `docs.md:5` states the `text` fence
rule, § Imports says `botopink format` flattens a group (measured) · `test-docs`: 112 fences, 0
failed.

## Open

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

A column re-derived once its backend front landed (multi-column rows: after the last). Non-`ok` row:
re-derive at HEAD (decisions turn `uncertain` into verdicts), then fix the test (`wrong-test`,
`weak`, `duplicate`, `skip-undocumented`) or register the `wrong-output`. Tests named *"lowers
byte-identically across backends"* hold or take decision 1's name.

**Acceptance (per report):**
- [ ] every non-`ok` row re-derived at HEAD and closed: fixed, registered (snapshot name, owning front's README) or struck with a reason
- [ ] the two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of `codegen-features.md:211`)
- [ ] status line appended to the report: columns covered, re-derivation date
- [ ] `scripts/snap_audit.sh --mode=review` after the batch: every struck row `ok` or absent from seeded verdicts

### Step 2 — wave B: the comptime reports (3.7–3.10)

After `01-checker`. Snapshots render inferred types: "JSON does not show the type" `weak` rows
gradeable. Batches landing in `comptime/infer.zig` conflict: one worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] no `src/comptime/tests/**` rename breaks a `comptime/errors/` pair (identical pair = `duplicate` row; dedup = rename)

### Step 3 — the `uncertain` rows no decision answers

Already closed: `lsp.md:104` `completion_decorator_record`, `lsp.md:103` `hover_interface_method`.

- [x] each remaining row answered in its report, or listed by name in the next milestone
- [x] no row carried as "uncertain" without a named owner or written reason

### Step 4 — three mis-named tests

`src/codegen/tests/externals.zig:55`, `:67` named for an unimplemented equivalence (`template
equivalent to @external(target, template)`, `mixed with @external() in one decl`); both bodies use
only `#[@External.Erlang(…), @External.Node(…)]`. `src/comptime/tests/infer_decls.zig:147` `"infer:
implement block is invisible to the binding list"` names a gone behaviour (`implement` blocks
appear, read from `OkData.transformed.decls`).

A fourth, found by step 5: `src/codegen/tests/wat.zig`'s `"wat: print ---- a record and a
variant have no printed form yet, so they trap"` — all four backends print §7's text now.

- [ ] the three tests named for what they assert; snapshots (codegen: one per target per runtime tree; comptime: one) `git mv`ed in the same commit, byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded

### Step 5 — comments in the test files

- `codegen/tests/control_flow.zig:73` ("pinned, 06-wasm" — `05-wasm`), `:76` ("07-checker's to
  land" — landed), `KNOWN (decision 8 §10 …)` note at `:535` (collection loop's `break <value>`
  answering `[20]` — decision 105: no loop has a value; test now reads a `var`)
- `codegen/tests/narrowing.zig:90` ("registered with 07-checker" — landed)
- `codegen/tests/builtins.zig:365` (commonJS "still lowers to `console.assert`" — decision 4 on all
  four backends)
- `comptime/tests/std_target_gating.zig:6`, `comptime/tests/infer_errors.zig:455` (retired
  `@external(<target>, …)` taught as current)
- `modules/language-server/src/tests/hover.zig:304` (`primitives.d.bp` — file is `primitives.bp`)

**Acceptance:**
- [x] `grep -rn '06-wasm\|07-checker\|F7 checker' modules/compiler-core/src/` empty; no `src/codegen/tests/**` comment describes a changed lowering
- [x] `grep -rIn 'primitives\.d\.bp' modules` = exactly the two extension-assertion tests (`cli/resolver.zig`, `lib-test-runner/src/discovery.zig`)
- [x] no comment presents retired `@external` as current; sites naming it **as retired** stay (`docs.md` § Host bindings, `codegen/AGENTS.md`, `comptime/AGENTS.md`'s R3 note, `scripts/AGENTS.md`'s `legacy` audit mode, the R3 refusal in `infer.zig`, `tests/language/reject/external_lowercase_target.bp`, the parser error fixtures)

### Step 6 — the `@BeamMemory` text into `docs.md`

`docs.md` has no `BeamMemory`. [`beam-memory-docs-text.md`](./beam-memory-docs-text.md) holds
`17-beam-memory`'s text, publishable now (17 step 1 on feat): part 1 into § Bindings, part 2 as §
`@BeamMemory`.

- [x] `docs.md` § Bindings has part 1, § `@BeamMemory` part 2 (`grep -c BeamMemory docs.md` > 0); `zig build test-docs` green with the new fences

### Step 7 — C-18's five document corrections, `docs.md:5` and § Imports

- Decisions 1 (async sequence = `@Stream<T>`), 2 (`?T` only — `Option.None` / `Some(1)` unbound), 10
  (`@code` annotation renamed), 25 (`is` does not bind), 32 (no `Option.Some` value names): every
  `docs.md`/`README.md` row with the old form corrected, measured by running the fence. At feat no
  fence spells `Option.Some` / `Option.None` / `AsyncIterator` (migration table names them retired).
- `docs.md:5` "a fence that is not a module … says so in a `docs-check` comment" stale: table =
  ```` ```text ```` fence, no comment (from `00-gate/114`).
- `docs.md` § Imports "there is no formatter rule that converts one into the other" (dot and group)
  is wrong: `botopink format` flattens a group into dotted leaves; codemod and fix-it write that
  spelling (from `129-import-without-from`).

- [x] no `docs.md` / `README.md` fence spells `Option.Some`, `Option.None`, `AsyncIterator`, `AsyncGenerator`, old `@code` or `is` binding a payload; `test-docs` green
- [x] `docs.md:5` states the `text` fence rule; `docs.md` § Imports says the formatter flattens a group into dotted leaves

### Step 8 — the lib-agnostic gate names every library (handed by `08-bpp`)

`build.zig`'s lib-agnostic gate greps `modules/compiler-core/src` for `rakun|jhonstart|erika` only;
`onze`, `emilia` occur in compiler-core comments (`codegen/erlang.zig`, `grep -n 'onze\|emilia'` —
02's file). Reword after 02 lands, then widen the pattern (`build.zig` is `26-cli-tooling`'s —
one-line carve-out named in the commit).

- [ ] `grep -riIwE 'rakun|jhonstart|erika|onze|emilia' modules/compiler-core/src` empty; gate pattern names all five

Measured 2026-10-08: the two test-file sites (`codegen/tests/control_flow.zig`, `dispatch.zig`)
reworded; the rest sits in files this front does not own — `ast.zig`, `comptime.zig`,
`module.zig`, `codegen/{erlang,commonJS,beam_asm}.zig`, `codegen/AGENTS.md`,
`codegen/js/AGENTS.md`, `comptime/{env,infer,transform}.zig`, `comptime/AGENTS.md`, `format.zig`,
`format/AGENTS.md`, `format/tests/{comments,declarations}.zig` — each a comment edit after its owner
lands. The pattern needs `-w`: without it `onze` matches `nonzero` (`commonJS.zig`'s
`isNonzeroLiteral`, test sources), so the gate would red on code.

### Step 9 — decision 8 §5.1's `->` arms (C-14)

`pattern -> value;` arms remain in emilia, jhonstart, rakun (erika none); `test/case_arrow_arms.bp`
is the transition guard beside `test/case_arms.bp`. Needs the maintainer's word before any rewrite;
each track rewrites its own tree.

- [ ] maintainer's answer recorded; if removed, §5.1 arms rewritten in emilia, jhonstart, rakun by the tracks, cells green; `docs.md` § Case re-measured for both forms

### Step 10 — erika's C-13 migration and C-12 reformat

erika has no track: `16-formatter/c13-migrate.py` over erika (28 sites at 1.0.10 — `16-formatter`
step 1 re-counts), then `botopink format` at C-12's rules once `16-formatter` step 6 (decision 345) lands.

- [ ] erika's `;` sites migrated by the script, cells green before/after, `botopink format --check` exit 0; reformat token-identical, idempotent
- [ ] erika's gate (`scripts/git-hooks/pre-commit`: `botopink test` per member, `botopink build` per example) green; `zig build test-libs -- --lib erika` / `--lib erika-linq` green in the meta worktree

### Step 11 — the pointers' sweep (last)

Five library pointers bumped in one sweep after each library's branch merges into its `feat`.
jhonstart's "always name the module" rule (`repository/jhonstart/AGENTS.md`) deletable since
`04-js`'s 1.0.10 step 5 — jhonstart track's edit, noted for the sweep.

- [ ] the five pointers bumped in one meta commit

### Step 12 — the per-cell dependency compile, measured (from 25)

Each `test-libs` cell recompiles `std` and the library from source (~4–6 s/cell at 1.0.10); `.beam`
cache and 00-gate/133's store do not cover a running cell's botopink compile. Re-measure cold
(`strace -f -e execve` + timestamp per stage) on one `emilia-*` and one rakun member. A content-keyed
compile cache in compiler-core (per-module output keyed by source bytes, options, compiler version)
= next milestone's front; this step files it with the measurement, edits no runner, nothing under
`compiler-core/**`.

**Measured 2026-10-08** (cold: the member's `.botopinkbuild/` and `out/` removed; `botopink build`
and `botopink test --target <t>`, the command `botopink-lib-test` spawns; a 16-core machine at load
average 29–32 from other fronts' gates, so absolute times read high):

| Cell | Target | Modules compiled | `build` wall / user | `test` wall / user | Tests |
|---|---|---|---|---|---|
| `emilia-theme` | commonJS | 12 (std, emilia, the example) | 10.3 s / 9.2 s (compile 9.2 s) | 11.6 s / 9.9 s (compile 12.0 s, then `node` 2.0 s, by `strace -tt`) | 10 pass |
| `emilia-theme` | erlang | 12 | 36.7 s / 35.2 s (botopink 12.7 s, the rest `erlc`) | 275 s / 246 s | 10 pass, each ≤ 1 ms |
| `rakun-cache` | erlang | 114 (`build`), 120 (`test`) | 11.7 s / 10.9 s (botopink 5.7 s) | 104 s / 22 s | 55 pass, 1 fail (below) |

(`rakun-cache` declares `"targets": ["erlang"]`; its commonJS build is refused at 37 modules with the
missing host binding — the audited exclusion, 3.9 s.) Of each cell's modules only the member's own
change between cells: 11 of 12 for an emilia example, ~110 of 114 for a rakun member are the same
std and library sources recompiled by every cell of the library. A content-keyed compile cache
(per-module output keyed by source bytes, options, compiler version) would answer those from the
store: up to the whole `build` compile per cell (~9 s commonJS, ~12.7 s + `erlc` on erlang per emilia
example, × 15 examples; ~5.7 s + `erlc` per rakun member, × 25 modules). The erlang `test` wall
is not compile alone: 246 s of CPU for 10 tests of ≤ 1 ms each, and rakun-cache's consumer tests
compile nested projects inside the test (10–24 s each) — the same cache serves both. A per-stage
`strace -f -e execve` of the erlang `test` could not be taken: under `strace -f` the test-run beam
never halts (the run printed its verdict and stayed resident; killed by PID). `rakun-cache`'s one red,
`consumer: the #[cached] twin …` (`test/consumer_test.bp:71`, `asserts.contains: needle not in
actual`), is the rakun track's to re-run.

- [x] the row: per cell, compile wall clock and CPU, dependency modules recompiled, commonJS and erlang; keyed cache's expected saving from it
- [x] spec stub in `../../deferred.md` (or next milestone's opening list) with this row as measurement

### Step 13 — the `async` delay flake (from 25)

`libs/std/src/async.bp`'s wall-clock assertion under load (maybe closed). std track re-measures;
answer recorded here.

**Measured 2026-10-08 by this front** (the std track filed no row): the flake's cause is gone from
the source — `async.bp`'s cells assert no upper bound on elapsed time (its test header: results and
order, order by signal through a gate, a lower bound only where the behaviour is a duration), and
the commonJS `delay` re-arms against `performance.now()` so it never answers early. The three
`async: delay` tests (`botopink test --target <t> --filter "async: delay"` in `libs/std`) ran 5×
on commonJS and 5× on erlang at load average 31–36 on 16 cores: 3 passed, 0 failed every run.
Closed; nothing filed.

- [x] std track's measurement recorded here, or row filed in `02-std-and-packaging`

**Gate:** standard (fronts.md § Gate) + traced run (`BOTOPINK_SNAP_TRACE`) after each batch: 0
orphans, traced = on disk; warm re-run: same pass count, 0 leaks, 0 `.snap.md.new`;
`scripts/snap_audit.sh --mode=runtime-parity` green after every rename · `zig build test-docs` and
`scripts/check-docs.sh` green after every document commit · every relative link of owned documents
resolves · erika commits on `front/07-residuals`, pointers on the same-named meta branch

## Notes

- **No emitted output changes here.** Such a row is registered in the owning front; a snapshot moves
  only by renaming its test.
- Report tables are the audit record: not edited except the per-report status line and step 1's strikes.
- The three `slugify`/`slugFromSrc` copies (`codegen/tests/helpers.zig`, `comptime/tests/helpers.zig`,
  `parser/tests/helpers.zig`) stay unmerged: every snapshot name depends on the `": "` truncation.
- Comment-only edit in another front's file: one commit per owning file, after that front lands.
- Runners ex-`25-gate-perf` (`scripts/{gate.sh,test-libs.sh,lib/pool.sh}`, `tests/language/run.sh`,
  `modules/test-shard/**`, `modules/lib-test-runner/**`): no open owner (115, 133 closed;
  `scripts/check-docs.sh` and `gate.sh` budget lines are `00-gate/114`'s) — an editing front names
  the carve-out in its commit.
