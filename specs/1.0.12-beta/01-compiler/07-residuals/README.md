# Front 07 — residuals: the snapshot review, the documents and comments, the ecosystem's tail

**Priority:** low · **State:** not started as a front (08's items 1–2 done by their owners, 09's
item 1 and 25's steps 2–3 done elsewhere)
**Depends on:** `02-erlang`, `03-beam`, `04-js`, `05-wasm` landed (steps 1 and 4 re-derive and rename
in their snapshot directories) · `01-checker` landed (step 2's shared root causes) · `16-formatter`
steps 1–2 (step 10) · the maintainer's word on C-14 (step 9) · every library track's merge into its
own `feat` (step 11, last) · `18-comptime-runtimes` step 4 (the transport test, its own)
**Owns:** the snapshot review — `modules/compiler-core/src/utils/snap.zig` (18 owns the directory
selection) · `scripts/snap_audit.sh` and its `scripts/AGENTS.md` section · `src/codegen/tests/**`
(a backend front's fixtures are its carve-out while it runs) · `src/comptime/tests/**` except
`helpers.zig` · `src/parser/tests/**` · `modules/language-server/src/tests/**` · the per-report
status lines in `specs/1.0.1-beta/06-snapshot-review/` · snapshot **renames** only (`git mv`,
byte-identical) — the documents — `repository/botopink-lang/docs.md` prose (with 23, 24; 114 owns
its marker and fence lines), `README.md`, `examples/**`, `libs/std/botopink.json`,
`libs/std/AGENTS.md` (with 23), the relative links of `specs/` ·
[`beam-memory-docs-text.md`](./beam-memory-docs-text.md) · comments in other fronts' files, only
after their owners — the ecosystem — `repository/erika/**` (with `02-std-and-packaging/98`, which
owns `erika/modules/erika-test/**`, `examples/erika-linq/README.md` and `erika/AGENTS.md`) · the meta
submodule pointers
**Does not touch:** any lowering (02–05), the checker and parser sources (01), `comptime/snapshot.zig`,
`codegen/snapshot.zig` (18), `libs/std/src/**` (the std track), `modules/language-server/src/**`
outside `src/tests/` (26), the other four library trees (their tracks), `c13-migrate.py` (16's —
run, not edited). A `wrong-output` row that needs one of these is **registered** in the owning
front's README with its snapshot name, never fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/` in steps 1–5 (except those
starting with `scripts/` or `modules/`, relative to `repository/botopink-lang/`), and to
`repository/botopink-lang/` from step 6 on. Report citations (`codegen-features.md:85`) are lines
in the 1.0.1-beta review reports.

## Goal

Every snapshot proves what its test claims (the 1.0.1-beta review's open rows re-derived and
closed), no comment or document teaches a retired form, `docs.md` carries the `@BeamMemory` text,
erika is migrated and reformatted, and the submodule pointers are bumped in one sweep.

## Mechanism

- **Orphan detection.** `BOTOPINK_SNAP_TRACE=<file>` at both `compareOrCreate` choke points,
  test helpers carrying `@src()` into the trace, `scripts/snap_audit.sh --mode=orphans`.
- **Review worksheet.** `scripts/snap_audit.sh --mode=review` emits one TSV row per unique snapshot
  with its test `file:line` and a verdict seeded from the reports by header cell.
- **The snapshot layout.** `snapshots/codegen/<runtime>/<target>/` under both comptime runtimes
  (`beam`, `wat`), checked equal by `--mode=runtime-parity`; `snapshots/comptime/{ast,errors,runtime,templates}/`;
  `snapshots/parser/`; `modules/language-server/snapshots/lsp/`. A test rename in
  `src/codegen/tests/**` moves one file per target in each runtime tree; anywhere else, one.
- **The reports.** Every report carries a `**Status (1.0.1-beta close)**` block telling the reader
  to re-derive each row at HEAD — not the status line steps 1–2 append. Re-derive, never trust a
  cited line. 3.11 `parser.md` and 3.12 `lsp.md` are closed; 3.3 and 3.6 are worked.

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

- 08 item 1 — `primitives.d.bp` swept from `erlang.zig` (02 step 11) and `comptime/` (01 step 14)
- 08 item 2 — the owners' `@external(` sweeps (01 step 14, 02 step 11)
- 09 item 1 — erika-linq's `"targets"` lifted; the ledger is deleted (00-gate/113)
- 25 step 2 — the hooks in worktrees: meta `scripts/worktree-add.sh`, meta `AGENTS.md` § Worktrees (00-gate/115)
- 25 step 3 — the gate re-timed after 00-gate: 12m16s → ~7m30s cold (00-gate/115, 133; decision 265)

## Open

### Step 1 — wave A: the codegen reports (3.1, 3.2, 3.4, 3.5, and 3.3's `:70`)

Split by backend: a report's column is re-derived once its backend front has landed; a row with
cells in several columns waits for the last. For every non-`ok` row: re-derive it at HEAD — many
closed with the backend fronts, and the decisions turn the `uncertain` rows into ordinary verdicts —
then fix the test (`wrong-test`, `weak`, `duplicate`, `skip-undocumented`) or register the
`wrong-output` in the owning front's README with its snapshot name. The tests named *"lowers
byte-identically across backends"* either hold or carry the name decision 1 implies.

**Acceptance (per report):**
- [ ] every non-`ok` row re-derived at HEAD and closed: fixed, registered with the snapshot name in the owning front's README, or struck with a written reason
- [ ] the two stale beam `null` rows struck (`codegen-control_flow.md:196`, the `{atom,nil}` half of `codegen-features.md:211`)
- [ ] a status line appended to the report naming which columns it covers and the date of the re-derivation
- [ ] `scripts/snap_audit.sh --mode=review` re-run after the batch: every row the report struck is `ok` or absent from the worksheet's seeded verdicts

### Step 2 — wave B: the comptime reports (3.7–3.10)

After `01-checker`. The comptime snapshots render the inferred types, so a row graded `weak` for
"the JSON does not show the type" is gradeable now. The batches whose `wrong-output` rows land in
`comptime/infer.zig` conflict with each other: one worker, one batch at a time.

**Acceptance:** as step 1, per report, plus:
- [ ] no test rename in `src/comptime/tests/**` breaks a `comptime/errors/` pair (a content-identical error pair is a `duplicate` row — deduplicating one is a rename)

### Step 3 — the `uncertain` rows no decision answers

Closed already: `lsp.md:104` `completion_decorator_record` and `lsp.md:103` `hover_interface_method`.

- [ ] each remaining row answered in its report, or listed by name in the next milestone
- [ ] no row carried as "uncertain" without a named owner or a written reason

### Step 4 — three mis-named tests

`src/codegen/tests/externals.zig:55` and `:67` are named for an equivalence the compiler does not
implement (`template equivalent to @external(target, template)`, `mixed with @external() in one
decl`); both bodies use `#[@External.Erlang(…), @External.Node(…)]` only.
`src/comptime/tests/infer_decls.zig:147` `"infer: implement block is invisible to the binding
list"` names a behaviour that is gone (`implement` blocks appear, read from `OkData.transformed.decls`).

- [ ] the three tests carry names that describe what they assert; their snapshot files (one per target in each runtime tree for the two codegen ones; one for the comptime one) renamed in the same commit by `git mv`, contents byte-identical
- [ ] `scripts/snap_audit.sh --mode=orphans` after the rename: 0 orphans, 0 unrecorded

### Step 5 — comments in the test files

- `codegen/tests/control_flow.zig:73` ("pinned, 06-wasm" — `05-wasm`), `:76` ("07-checker's to
  land" — landed), and the `KNOWN (decision 8 §10 …)` note at `:535` (a collection loop's
  `break <value>` answering `[20]` — decision 105: no loop has a value; the test now reads a `var`)
- `codegen/tests/narrowing.zig:90` ("registered with 07-checker" — landed)
- `codegen/tests/builtins.zig:365` (commonJS "still lowers to `console.assert`" — decision 4 is
  implemented on all four backends)
- `comptime/tests/std_target_gating.zig:6`, `comptime/tests/infer_errors.zig:455` (the retired
  `@external(<target>, …)` form taught as current)
- `modules/language-server/src/tests/hover.zig:304` (`primitives.d.bp` — the file is `primitives.bp`)

**Acceptance:**
- [ ] `grep -rn '06-wasm\|07-checker\|F7 checker' modules/compiler-core/src/` returns nothing; no comment in `src/codegen/tests/**` describes a lowering the backends have changed
- [ ] `grep -rIn 'primitives\.d\.bp' modules` returns exactly the two extension-assertion tests (`cli/resolver.zig`, `lib-test-runner/src/discovery.zig`)
- [ ] no comment presents a retired `@external` form as current; the sites that name it **as retired** stay (`docs.md` § Host bindings, `codegen/AGENTS.md`, `comptime/AGENTS.md`'s R3 note, `scripts/AGENTS.md`'s `legacy` audit mode, the R3 refusal in `infer.zig`, `tests/language/reject/external_lowercase_target.bp`, the parser error fixtures)

### Step 6 — the `@BeamMemory` text into `docs.md`

`docs.md` has no `BeamMemory` mention. [`beam-memory-docs-text.md`](./beam-memory-docs-text.md)
holds the text `17-beam-memory` supplies, both parts publishable now (17 step 1 is on feat): part 1
into § Bindings, part 2 as § `@BeamMemory`.

- [ ] `docs.md` § Bindings carries part 1 and § `@BeamMemory` part 2 (`grep -c BeamMemory docs.md` > 0); `zig build test-docs` green with the new fences

### Step 7 — C-18's five document corrections, and `docs.md:5`

Decision 1 (the async sequence type is `@Stream<T>`), 2 (`?T` only — `Option.None` / `Some(1)` are
unbound), 10 (the `@code` annotation renamed), 25 (`is` does not bind), 32 (no `Option.Some` value
names): each row of `docs.md` and `README.md` that still writes the old form corrected, measured by
running the fence. At feat no fence spells `Option.Some` / `Option.None` / `AsyncIterator`
(`docs.md`'s migration table names them as retired). And `docs.md:5` — "a fence that is not a
module … says so in a `docs-check` comment" — is stale: a table is a ```` ```text ```` fence, no
comment (handed by `00-gate/114`).

- [ ] no `docs.md` / `README.md` fence spells `Option.Some`, `Option.None`, `AsyncIterator`, `AsyncGenerator`, the old `@code` annotation or `is` binding a payload; `test-docs` green
- [ ] `docs.md:5` states the `text` fence rule

### Step 8 — the lib-agnostic gate names every library (handed by `08-bpp`)

`build.zig`'s lib-agnostic gate greps `modules/compiler-core/src` for `rakun|jhonstart|erika` only;
`onze` and `emilia` occur in compiler-core comments (`codegen/erlang.zig`, measured: `grep -n
'onze\|emilia'` — 02's file). The comments are reworded after 02 lands, then the pattern widens
(`build.zig` is `26-cli-tooling`'s — the one-line carve-out named in the commit).

- [ ] `grep -riIE 'rakun|jhonstart|erika|onze|emilia' modules/compiler-core/src` returns nothing; the gate's pattern names all five

### Step 9 — decision 8 §5.1's `->` arms (C-14)

`case` arms written `pattern -> value;` are left in emilia, jhonstart and rakun (erika has none).
`test/case_arrow_arms.bp` is the transition guard beside `test/case_arms.bp`. The row needs the
maintainer's word on whether the `->` arm leaves the language before any tree is rewritten; the
rewrite is each track's on its own tree.

- [ ] the maintainer's answer recorded; under removal, §5.1 arms rewritten in emilia, jhonstart and rakun by the tracks, each cell green after its rewrite; `docs.md` § Case re-measured for both arm forms

### Step 10 — erika's C-13 migration and C-12 reformat

erika has no track this milestone, so its share is here: `16-formatter/c13-migrate.py` over erika
(28 sites at 1.0.10's count — `16-formatter` step 1 re-counts), then `botopink format` at C-12's
rules once 16-a/16-b are confirmed.

- [ ] erika's `;` sites migrated by the script, the cells green before and after, `botopink format --check` exit 0; the reformat token-identical and idempotent
- [ ] erika's own gate (`scripts/git-hooks/pre-commit`: `botopink test` per member, `botopink build` per example) green; `zig build test-libs -- --lib erika` / `--lib erika-linq` green in the meta worktree

### Step 11 — the pointers' sweep (last)

The submodule pointers of the five libraries bumped in one sweep after each library's branch merges
into its own `feat`. The jhonstart "always name the module" rule (`repository/jhonstart/AGENTS.md`)
is deletable since `04-js`'s 1.0.10 step 5 — the jhonstart track's edit, noted so the sweep sees it.

- [ ] the five pointers bumped in one meta commit

### Step 12 — the per-cell dependency compile, measured (from 25)

Every `test-libs` cell compiles the same dependency modules (`std`, the library) from source
(~4–6 s a cell at 1.0.10's measurement); the `.beam` cache removed the erlang recompile, and
00-gate/133's cell-result store skips a cell whose key did not change — not the botopink compile of
a cell that runs. Re-measure on a cold run (`strace -f -e execve` and a timestamp per stage) on one
`emilia-*` member and one rakun member. A content-keyed compile cache in compiler-core (the
pipeline's output per module keyed by source bytes, options and compiler version) is a front of
its own in the next milestone; this step files it with the measurement and edits no runner and
nothing under `compiler-core/**`.

- [ ] the row: per cell, the botopink compile's wall clock and CPU, the dependency modules recompiled, on commonJS and erlang; the keyed cache's expected saving computed from it
- [ ] a spec stub in `../../deferred.md` (or the next milestone's opening list) with this row as its measurement

### Step 13 — the `async` delay flake (from 25)

`libs/std/src/async.bp`'s wall-clock assertion under load (possibly closed since). The std track
re-measures; this front records the answer.

- [ ] the std track's measurement recorded here, or the row filed in `02-std-and-packaging`

**Gate:** standard (fronts.md § Gate) + a traced run (`BOTOPINK_SNAP_TRACE`) after each batch: 0
orphans, traced = on disk; `scripts/snap_audit.sh --mode=runtime-parity` green after every rename ·
`zig build test-docs` and `scripts/check-docs.sh` green after every document commit · every relative
link of the documents this front owns resolves · library commits in erika on `front/07-residuals`,
the pointers on the meta branch of the same name

## Notes

- **Nothing here changes emitted output.** A row that would is registered in the owning front. A
  snapshot moves only by renaming its test.
- The reports' tables are the audit record and are not edited, except for the status line per
  report and the strikes step 1 asks for.
- The three copies of `slugify`/`slugFromSrc` (`codegen/tests/helpers.zig`,
  `comptime/tests/helpers.zig`, `parser/tests/helpers.zig`) are not merged: the `": "` truncation is
  a behaviour every snapshot name depends on.
- A comment-only edit in another front's file is one commit per owning file, after that file's
  front lands.
- The runners `25-gate-perf` owned (`scripts/{gate.sh,test-libs.sh,lib/pool.sh}`,
  `tests/language/run.sh`, `modules/test-shard/**`, `modules/lib-test-runner/**`) have no open owner
  since 00-gate's 115 and 133 closed (`scripts/check-docs.sh` and `gate.sh`'s budget lines are
  `00-gate/114`'s); a front that must edit one names it as a carve-out in its commit.
</content>
</invoke>
