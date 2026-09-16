# Front 09 — review-tooling

**Priority:** medium — the harness is trustworthy now; what is left is keeping the snapshot set
honest over time, the backlog the review exposed, and four language questions that block rows in
several reports at once
**Depends on:** nothing to start. [`../02-cli-gate/`](../02-cli-gate/README.md) should land first
because it widens the gate this front's steps are verified under. **Step 3 is the gate for step 4**
— fixing a row before its semantics question is answered records the wrong answer in a snapshot
**Owns:** `src/utils/snap.zig` · `scripts/snap_audit.sh` · `src/codegen/tests/**` ·
`src/comptime/tests/**` (shared with [`../10-comptime-dedup/`](../10-comptime-dedup/README.md) for
`helpers.zig` — this front lands first) · the four decisions in
[`semantics-decisions.md`](./semantics-decisions.md) (the *rule*, not its lowering). Not listed in
[`../fronts.md`](../fronts.md#ownership) and owned by no other front, so claimed here:
`modules/language-server/src/tests/snapshot.zig` (step 1 needs it), `src/parser/tests/**` and
`modules/language-server/src/tests/**` (the test-side rows of reports 3.11 and 3.12),
`scripts/AGENTS.md` (the `scripts/snap_audit.sh` section only — `scripts/**` is otherwise
[`../02-cli-gate/`](../02-cli-gate/README.md)'s)
**Does not touch:** any backend's lowering — `src/codegen/beam_asm.zig`
([`../04-beam/`](../04-beam/README.md)), `src/codegen/erlang.zig`
([`../05-erlang/`](../05-erlang/README.md), [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)),
`src/codegen/wat.zig` ([`../06-wasm/`](../06-wasm/README.md)), `src/codegen/commonJS.zig`
([`../08-js-bridges/`](../08-js-bridges/README.md)) · the checker, `src/comptime/infer.zig` and
friends ([`../07-checker/`](../07-checker/README.md)) · `src/comptime/snapshot.zig`
([`../10-comptime-dedup/`](../10-comptime-dedup/README.md)) · `libs/std/**`
([`../03-std-surface/`](../03-std-surface/README.md)). A `wrong-output` row that needs one of these
is registered in that front with its snapshot name, not fixed here.

Paths are relative to `repository/botopink-lang/modules/compiler-core/`, except those starting with
`scripts/` or `modules/`, which are relative to `repository/botopink-lang/`. Every `file:line` is at
`botopink-lang` HEAD, measured 2026-09-16. The review reports cited as `<report>.md:<line>` live in
[`../../1.0.1-beta/06-snapshot-review/`](../../1.0.1-beta/06-snapshot-review/) and stay there.

This front runs **alone or first** among the harness fronts: it changes which tests run and how
their snapshots are triaged, so every other front's `.snap.md.new` triage moves underneath it
([`../fronts.md`](../fronts.md) note 4).

---

## Problem

Three things the 1.0.1-beta review left that the fix waves did not reach.

1. **Nothing reports an orphan snapshot.** A snapshot's file name is the slug of its test's
   description, so renaming or deleting a test leaves the old file on disk and every run stays
   green. Reproduce: rename any `test "…"` in `src/codegen/tests/features.zig`, run
   `BOTOPINK_SNAP_CREATE=1 zig build test` — a new file appears, the old one stays, nothing fails
   (`compareOrCreate`, `src/utils/snap.zig:73`, only ever reads the path it is handed).
2. **Nothing relates a snapshot to its test.** `scripts/snap_audit.sh --mode=` accepts only
   `runlog`, `legacy`, `values`, `coverage` (`scripts/snap_audit.sh:9`, `:47-52`); none of them
   emits test `file:line` or a verdict. The twelve review reports were built by hand and their
   table shapes differ.
3. **Four cross-backend semantics questions are unanswered**, and they block rows in several
   reports at once: the text `@print` produces, the value of a block, the representation of `null`,
   and whether `assert` does anything outside test mode (it is a no-op on beam and wasm today).

## Current state

The harness contract landed: the RUN LOG is decided by exit status, a failing compile fails its
snapshot test (or records a `COMPILE DIAGNOSTIC` when the test is about the failure), a missing
snapshot fails without `BOTOPINK_SNAP_CREATE=1` (`src/utils/snap.zig:61-67`), every backend is
compared in one round, and `HARNESS_VERSION` is in the runtime cache key. `*.snap.md.new` is
git-ignored.

Measured at HEAD with `rtk proxy find … -name '*.snap.md' | wc -l`:

| | |
|---|---|
| `*.snap.md` | 2442 — 2342 under `modules/compiler-core/snapshots/`, 100 under `modules/language-server/snapshots/lsp/`; 0 `*.snap.md.new` on disk |
| per suite | `codegen/{commonJS,erlang}` 279 · `codegen/{beam,wasm}` 278 · `codegen/errors` 4 · `parser` 215 · `comptime` 1009 (1008 per-backend copies of 305 unique + `templates/` 1 — see [`../10-comptime-dedup/`](../10-comptime-dedup/README.md)) |
| `zig build test` | green, 0 leaks |
| wasm RUN LOGs | all empty — `executeWat` (`src/codegen/runtime.zig:547-558`) returns `""` unconditionally; owned by [`../06-wasm/`](../06-wasm/README.md) |

**Snapshot writers.** There are exactly two choke points, one per module:
`compareOrCreate` in `src/utils/snap.zig:73` (codegen, comptime and parser suites, all via
`checkText`, `:46`) and `compareOrCreate` in `modules/language-server/src/tests/snapshot.zig:55`
(LSP, `SNAP_DIR = "snapshots/lsp"` at `:31`).

**Slugs.** The slug rule (`slugFromSrc` → `slugify`: strip `test.`, drop everything up to the first
`": "`, lowercase alnum, runs of other bytes → `_`) is **not** in `src/utils/snap.zig`; it is copied
three times: `src/codegen/tests/helpers.zig:37, 79`, `src/comptime/tests/helpers.zig:21, 63`,
`src/parser/tests/helpers.zig:15, 61`. The `": "` truncation is the cause of several `wrong-test`
rows (e.g. `comptime-errors-effects.md:98-99`) and of six pairs of byte-identical error snapshots
written by different tests (listed under `comptime-generics-effects-decorators.md`
`## Comptime orphans / missing / copies`, `:166`).

**The backlog.** 783 evidence rows across the twelve reports, **777 open**. Per report, per class,
and where to read each: [`backlog.md`](./backlog.md).

| Class | Open |
|---|---|
| `wrong-output` | 397 |
| `weak` | 180 |
| `wrong-test` | 126 |
| `duplicate` | 30 |
| `known` | 25 |
| `uncertain` | 14 — 7 answered by the four decisions, 7 separate questions |
| `legacy-syntax` | 4 |
| `skip-undocumented` | 1 |

**The four decisions.** Each with today's behaviour per backend (`file:line`), the options, a
recommendation and what depends on it: [`semantics-decisions.md`](./semantics-decisions.md). Two
corrections the analysis made against the reports: the beam `null` half is already fixed at HEAD
(`src/codegen/beam_asm.zig:1843-1850` emits `{atom, undefined}`), and `assert` has **zero** lowering
in `src/codegen/beam_asm.zig` and `src/codegen/wat.zig` — it is not a severity question.

## Mechanism

- **Orphans** exist because the path is derived, not declared: `slugFromSrc` reads
  `@src().fn_name` at comptime, so the only record of which paths a run checked is the set of
  `compareOrCreate` calls made during that run. Nothing collects it.
- **The worksheet** cannot be built from the snapshot tree alone for the same reason — the test
  `file:line` is only known to the Zig test that computed the slug. A trace of `compareOrCreate`
  calls, if it carries `@src()`, is the missing join key for step 2 as well as step 1.
- **The decisions** are blocked because each backend implemented its own reading and no document
  states the language's: see [`semantics-decisions.md`](./semantics-decisions.md) for the deciding
  line per backend.

## Steps

### Step 1 — Orphan detection

Add an opt-in `BOTOPINK_SNAP_TRACE=<file>`: when set, both `compareOrCreate` choke points
(`src/utils/snap.zig:73`, `modules/language-server/src/tests/snapshot.zig:55`) append the checked
path — and, where the caller can pass it, the test's `@src()` `file:line` — one per line. Run the
full suite with it, then diff the sorted trace against
`find modules/compiler-core/snapshots modules/language-server/snapshots -name '*.snap.md'`.

The trace must be append-safe under Zig 0.16's parallel test runner (open with append, one `write`
per line), or the diff reports false orphans.

**Acceptance:**
- [ ] `BOTOPINK_SNAP_TRACE=/tmp/trace zig build test` writes one line per checked snapshot, from
      both modules
- [ ] Orphan list produced from a full run; it is empty, or every entry is deleted
- [ ] Unset, the variable changes nothing: snapshots byte-identical, same pass count

### Step 2 — Review worksheet

Add `scripts/snap_audit.sh --mode=review`, emitting one TSV row per **unique** snapshot: `suite`,
`slug`, `test file:line`, `path(s)` (the comptime copies collapse to one row with all paths until
[`../10-comptime-dedup/`](../10-comptime-dedup/README.md) lands), `verdict`. Build it from step 1's
trace; seed `verdict` from the reports.

Seeding must not assume a table shape: the `verdict` column index varies per table, `re-check` is
4th in some reports, last in others and inline in two, `lsp.md` alone has a `sev` column, and
`parser.md` splits by class into seven tables (see [`backlog.md`](./backlog.md) caveats). Locate the
column by its header cell, as the backlog count did.

**Acceptance:**
- [ ] `--mode=review` emits a row for every snapshot in every suite (codegen, comptime, parser, lsp)
- [ ] Every row has a test `file:line`; a row without one is an orphan and step 1 already failed
- [ ] `scripts/AGENTS.md` documents `BOTOPINK_SNAP_TRACE` and `--mode=review`

### Step 3 — Decide the cross-backend semantics the review could not

Four questions, each written up in [`semantics-decisions.md`](./semantics-decisions.md): the text
`@print` produces ([decision 1](./semantics-decisions.md#decision-1)), the value of a block and of a
fn body's tail ([2](./semantics-decisions.md#decision-2)), the representation of `null`
([3](./semantics-decisions.md#decision-3)), the severity of `assert`
([4](./semantics-decisions.md#decision-4)). Decide them, write the decision into the language
reference or `src/codegen/AGENTS.md`; the blocked rows then become ordinary `wrong-output` fixes in
the fronts that own the lowering.

| # | Recommendation |
|---|---|
| 1 | C — a runtime-dispatching `__bp_print/1` helper on erlang and beam (`~ts` for binaries, `~p` otherwise); numeric formatting stays divergent, documented |
| 2 | B — a block is a statement; its value is `break <e>`; the checker rejects a valueless block in value position and a non-`unit` fn that falls off the end |
| 3 | C — on wasm, box `?T` as a linear-memory offset with `0` = null; beam is already `undefined` |
| 4 | A — `assert` is always fatal, with message and `file:line`, on all four backends |

**Acceptance:**
- [ ] All four decisions written down, in the language reference or `src/codegen/AGENTS.md`, each
      with the acceptance listed under it in [`semantics-decisions.md`](./semantics-decisions.md)
      registered in the front that implements it
- [ ] Decision 3's wasm carrier agreed with [`../06-wasm/`](../06-wasm/README.md) step 6 (which
      currently suggests a sentinel)
- [ ] The two stale beam `null` rows struck in their reports with the reason

### Step 4 — Act on the per-report residuals

Each report is file-disjoint and can be handled in its own branch. For every non-`ok` row that is
not withdrawn: re-derive it at HEAD, then fix the test (`wrong-test`, `weak`, `duplicate`,
`skip-undocumented`, `legacy-syntax`) or register the `wrong-output` in the front that owns the file
with the snapshot name ([`backlog.md` § Where a closed row lands](./backlog.md#where-a-closed-row-lands)).

Order: the codegen reports 3.1, 3.2, 3.4, 3.5 after step 3 (they carry the `uncertain` rows); the
comptime reports 3.7–3.10 after [`../07-checker/`](../07-checker/README.md) lands its shared root
causes and after [`../10-comptime-dedup/`](../10-comptime-dedup/README.md) step 2, which turns many
of their `weak` rows into `ok` or a real `wrong-output` with no test change.

**Acceptance (per report):**
- [ ] Every non-`ok` row re-derived at HEAD and closed: fixed, registered in the owning front with
      the snapshot name, or struck with a written reason
- [ ] A short status line appended to the report saying what closed it
- [ ] The 7 `uncertain` rows no decision answers ([`backlog.md`](./backlog.md#the-7-uncertain-rows-no-decision-answers))
      each answered or carried forward by name

## Gate

- [ ] `zig build test` from a **cold** runtime cache (`modules/compiler-core/.botopinkbuild/runtime-cache`
      deleted), green in this front's worktree, and again on the warm cache it leaves: same pass
      count, 0 leaks, 0 `.snap.md.new` on disk
- [ ] Orphan list empty from a traced run
- [ ] 0 empty and 0 source-only snapshots unless the test documents why (holds today — keep it)
- [ ] `AGENTS.md` of the snapshot-producing directories and `scripts/AGENTS.md` updated in the same
      commit
- [ ] Commit on `fix/review-tooling`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Steps 1–2 change no snapshot.** They add an env-gated side effect and a script mode.
- **Step 3 changes no file here beyond prose**, but every decision moves snapshots in other fronts
  when it is implemented: decision 1 re-records erlang and beam RUN LOGs that print strings (and
  retires the representation mapping the beam/erlang/wasm fronts compare under); decision 2 turns
  fixtures like `case_nested_case_in_block_arm` into checker errors (07-checker, all four codegen
  directories); decision 3 changes every wasm optional (06-wasm, W7's 4 fixtures and whatever moves
  with the carrier); decision 4 adds lowerings to beam and wasm and changes node and erlang output
  outside test mode (`assert_*` in all four directories).
- **Step 4 deletes and renames tests.** A `duplicate` or `wrong-test` fix renames a slug, which moves
  its snapshot file — in `src/comptime/tests/**` that is four files today, one after
  [`../10-comptime-dedup/`](../10-comptime-dedup/README.md). Run step 1's trace after each batch.
- **Ownership gap.** `scripts/snap_audit.sh` is listed under both this front and
  [`../02-cli-gate/`](../02-cli-gate/README.md) (`scripts/**`) in [`../fronts.md`](../fronts.md);
  and `modules/language-server/**` is owned by nobody. Both are claimed above for the named files
  only; if 02-cli-gate is in flight, sequence the `scripts/` edit after it.

## Notes

- The reports' tables are the audit record and are not copied here or edited, except for the
  per-report status line step 4 appends and the strikes step 3 asks for.
- `misnamed`/`naming` is not a verdict class; `withdrawn` is a disposition, not a verdict; `orphan`
  is declared in 8 summary tables but never used as an evidence row.
- The three copies of `slugify`/`slugFromSrc` are not merged here — the `": "` truncation is a
  behaviour every existing snapshot name depends on; changing it is a rename of hundreds of files and
  belongs in its own step once step 1 can prove nothing was orphaned.
- The comptime AST renderer (`?`, `"id": 0`, missing declaration kinds) and the four comptime copies
  are [`../10-comptime-dedup/`](../10-comptime-dedup/README.md), not this front.
