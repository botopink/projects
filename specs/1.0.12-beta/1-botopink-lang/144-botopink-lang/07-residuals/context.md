# Front 07 — residuals: the snapshot review, the documents and comments, the ecosystem's tail

> **Former front — context only** (decision 433): its goal, mechanism and notes, kept beside the steps that took its open work — [144-botopink-lang](../README.md): s1 → B-29 · s2 → B-29 · s4 → B-29 · s8 → B-29 · s9 → B-29; [145-erika](../../../2-libraries/145-erika/README.md): s10 → 145 s3; [163-meta-ci](../../../3-medium/163-meta-ci/README.md): s11 → 163 s2. Its done steps are in git history, `decisions-taken.md` and the 1.0.11 closure.

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
23), relative links of `specs/` · [`beam-memory-docs-text.md`](beam-memory-docs-text.md) ·
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
