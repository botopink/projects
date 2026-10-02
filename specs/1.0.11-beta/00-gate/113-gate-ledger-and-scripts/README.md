# Front 113 — gate-ledger-and-scripts: the manifest is the single source of truth; the two ledgers are deleted; a restriction is audited, not counted

**Priority:** critical — it is what turns "84 passed, 36 failed, 13 restricted" into a two-number
line where the second is 0, and it cannot be written before the library fronts land.
**Depends on:** `99`, `100`, `101`, `108`, `109` — every cell the manifests declare is green in
their trees, and the guards exist in the five repositories; `111` and `112` for
`compiler-cli/src/cli/test_cmd.zig` (step 4b edits it after their landings). `115` starts from
this front's `test-libs.sh` and `lib-test-runner`.
**Owns:** `scripts/restricted-targets.txt` (deleted) · `scripts/known-red-libs.txt` (deleted) ·
`scripts/test-libs.sh` · `modules/lib-test-runner/**` (the `--include-unsupported` flag and the
`restricted` status deleted; the restriction audit added) · `scripts/AGENTS.md` (§ test-libs.sh,
§ known-red-libs.txt, § restricted-targets.txt) · `modules/lib-test-runner/AGENTS.md` ·
`modules/compiler-cli/src/cli/test_cmd.zig` (the `BOTOPINK_BIN` export only, step 4b) ·
`.github/workflows/test.yml:13-23` (the `libs` job's header comment only — the job's steps are
114's) · the meta repository's `scripts/language-gap-markers.sh` (new; `115` owns
`scripts/worktree-add.sh` beside it) and this milestone's `language-gaps.md` row stubs (step 4c) ·
verification (read-only) of `repository/{rakun,jhonstart,emilia,onze,erika}/.gitignore` and
`scripts/git-hooks/**`.
**Does not touch:** any library repository's files (the five fronts own them; this front *checks*
them and reports); `scripts/gate.sh` (115's); `tests/language/**` (111's).

---

## Problem

```
$ zig build test-libs
…
test-libs: 84 passed, 36 failed, 0 known red, 13 restricted (pinned), 0 skipped, 9 without tests
test-libs: restricted cells missing from scripts/restricted-targets.txt: onze-cli·erlang(build) onze-og·commonJS(build) onze-server·commonJS(build) rakun-cli·commonJS(build) … (21)
test-libs: pinned failed counts that moved (pinned→measured): rakun·commonJS(30→31) rakun-actuator-api·commonJS(2→1) rakun-app·commonJS(2→6) rakun-cache·commonJS(build→8) rakun-data·commonJS(5→14) rakun-messaging·commonJS(build→4) rakun-scheduling·commonJS(6→7) rakun-security·commonJS(9→13) rakun-web·commonJS(9→8)
```

Measured at the open (`libs.txt:12340-12343`). Three of the four numbers after "passed" are
tolerance: `known red` (a file that pins a red to a library commit), `restricted (pinned)` (a file
that pins a failed *count*), and the two refusals that follow. `scripts/AGENTS.md:277` still says
"Live entries: `rakun-data erlang` and `rakun-security erlang`" for a file that has no line.

## Current state

| File | Lines | State at the open |
|---|---|---|
| `scripts/restricted-targets.txt` | 21 (`:53-82`) | 3 pin `0` (a passing cell), 1 pins `1` (`jhonstart-dom-test·erlang`, structural), 17 are rakun `commonJS` (a row decision 113 says does not exist); 21 cells missing, 9 counts moved |
| `scripts/known-red-libs.txt` | 0 live | header only; `scripts/AGENTS.md:277` stale |
| `scripts/test-libs.sh` | `:326` always `--include-unsupported`; `:238-272` the ledger comparison; `:99-151` the known-red machinery; `:329-369` the stale-line refusals | every cell runs regardless of its manifest; the verdict of a restricted cell is the ledger's |
| `modules/lib-test-runner/src/discovery.zig:301-308` | `libRunsTarget = include_unsupported or libSupportsTarget` | the manifest decides only without the flag |
| `modules/lib-test-runner/src/main.zig:176-193`, `:225-235` | `restricted` computed and carried into every cell summary; `.skipped` "never fails the run (even under --strict)" | a restricted cell is a `~` |

Under gate-a (recommended (b)) and gate-d (recommended (b)):

- a member runs on the targets its manifest declares and on no other — no `--include-unsupported`,
  no `restricted` status, no ledger;
- a manifest that excludes a target is **audited** on every run: the runner runs `botopink build
  --target <excluded>` for the member and accepts the exclusion only when the build's first error
  is a host-binding refusal (`has no #[@External.<Target>]`, `external_missing`, "host module …
  missing"); a member that builds on the excluded target, or fails for any other reason, fails
  the run naming the member and the target ("the restriction is not structural — delete the
  `targets` line, or file the compiler row that makes the build refuse it");
- `known-red-libs.txt` is deleted with its machinery: a red cell is red.

The audit costs one `botopink build` per excluded (member, target) — at the open 35 rakun
commonJS + 3 onze + 1 jhonstart = 39 builds, each the closure compile the cell would have cost;
115 budgets it (and its dependency-closure cache halves it).

## Mechanism

`test-libs.sh:326` makes the flag unconditional and `main.zig:184` turns every manifest exclusion
into a ran-and-measured cell whose verdict `test-libs.sh:238-272` reads off the ledger. Delete the
flag and the manifest decides; add the audit and the manifest cannot lie.

## Steps

### Step 1 — measure the green matrix on the five landed trees

With 99, 100, 101, 108, 109 in one checkout: `zig build test-libs` once, ledger as is. Expected:
`0 failed`; every `restricted` line either "as pinned" or "stale" (the widened cells); the 21
missing lines still reported. Record the cell list here — it is the list step 3 asserts.

**Acceptance:**
- [ ] the run's `FAILED cells:` line is absent; the passed count and the `restricted` set recorded in this README

### Step 2 — the runner: manifest rule and restriction audit (gate-a, gate-d)

`lib-test-runner`: delete `--include-unsupported` (`args.zig:61-65,142-143`, its tests),
`libRunsTarget` (`discovery.zig:301-308`) becomes `libSupportsTarget`, the `restricted` field and
`skipped_unsupported` arm (`main.zig:176-193,225-235`) go — a target the manifest excludes is not
a cell; `--strict` loses nothing (there is no soft verdict left to harden). Add the audit: for each
(member, excluded target) where the target is one `botopink test` can run, spawn `botopink build
--target <t>` in the member with a throwaway `--out`; classify the first error; emit a `cell_summary`
of a new kind `restriction_audit` with `ok` or `not_structural` and the line. A `not_structural`
fails the run. The compiler knows no library: the classifier reads the diagnostic's error id, not a
library name.

**Acceptance:**
- [ ] `botopink-lib-test --help` has no `--include-unsupported`; `grep -rn "include_unsupported\|restricted" modules/lib-test-runner/src` → 0 (except the audit's own words)
- [ ] a synthetic workspace in `lib-test-runner`'s tests: a member with `"targets": ["erlang"]` and an `@External.Erlang`-only cell → audit `ok`; the same member with the binding given a Node form → audit `not_structural`, exit 1
- [ ] the audit runs the 39 (member, target) pairs at the open: all `ok` (rakun's 35 by `has no #[@External] for the node backend`; `onze-server·commonJS` the same through rakun; `onze-cli·erlang`, `onze-og·commonJS`, `jhonstart-dom-test·erlang` by their own host cells — 100 and 101 recorded the lines)

### Step 3 — `test-libs.sh`: two ledgers gone, one line printed

Delete the known-red functions (`:99-151`), the ledger functions (`:157-182`), the restricted arm
(`:238-277`), the refusal loops (`:329-369`), the `BOTOPINK_KNOWN_RED_LIBS` /
`BOTOPINK_RESTRICTED_TARGETS` overrides (a configuration that swaps the ledger is a bypass —
decision 67); delete `scripts/restricted-targets.txt` and `scripts/known-red-libs.txt`. The summary
line becomes `test-libs: <passed> passed, <failed> failed, <n> without tests` plus the audit's
count; exit 1 on any failed cell, any `not_structural` audit, or a workspace document mismatch.

**Acceptance:**
- [ ] `test ! -e scripts/restricted-targets.txt -a ! -e scripts/known-red-libs.txt`
- [ ] `zig build test-libs` → `test-libs: 123 passed, 0 failed, 9 without tests, 39 restrictions audited` (123 = step 1's passed count; re-derive — the number is the manifests' cell count, and a front that adds a member moves it)
- [ ] `grep -rn "restricted-targets\|known-red-libs\|include-unsupported" scripts .github modules/lib-test-runner docs.md README.md` → 0 (the `libs` job comment `.github/workflows/test.yml:13-23` rewritten)

### Step 4 — `scripts/AGENTS.md` and `modules/lib-test-runner/AGENTS.md`

§ known-red-libs.txt (`:261-278`) and § restricted-targets.txt (`:280-323`) deleted; § test-libs.sh
(`:226-259`) says: the manifest decides the matrix, a restriction is audited on every run, a cell
that exists is green or the run fails, no environment variable changes any of it; the tree listing
`:20-22` loses the two files. `lib-test-runner/AGENTS.md` the same for the flag and the audit.

**Acceptance:**
- [ ] `grep -c "Live entries" scripts/AGENTS.md` = 0

### Step 4b — `botopink test` exports the compiler's own path to the test process

Report L's latent CI red: `rakun-client` has 7 fixture-build tests (green 70/0 with `BOTOPINK_BIN`
set) that spawn the compiler on a fixture project; the fallback path
`../../../botopink-lang/zig-out/bin/botopink` exists in the meta layout only, and neither
`test-libs.sh` nor `botopink test` exports the variable — every fixture-build test fails in CI's
layout the day CI runs more than the core member (which gate-j's fronts make it do). The fix is
generic and library-agnostic: `botopink test` (`compiler-cli/src/cli/test_cmd.zig`) sets
`BOTOPINK_BIN` in the test process's environment to its own executable path (`std.fs.selfExePath`)
when the variable is unset — a test that spawns "the compiler running me" spawns the right one in
every layout; `test-libs.sh` needs nothing. The variable's meaning is documented in
`modules/compiler-cli/AGENTS.md` and `docs.md` § testing (one sentence — 114's docs pass does not
own the sentence; it is this front's).

**Acceptance:**
- [ ] a `compiler-cli/tests/*.sh` contract: a test that prints `env.read("BOTOPINK_BIN")` under `botopink test` prints the running binary's path; with the variable pre-set, the pre-set value
- [ ] `zig build test-libs -- --lib rakun-client --target erlang` → `pass` with no `BOTOPINK_BIN` in the shell

### Step 4c — the `// LANGUAGE GAP` marker check lists every note without a row

The five notes report L found in library code, none with a `language-gaps.md` row: emilia
`src/tokens.bp:2194` (a negative leaf); rakun `modules/rakun/src/conditions.bp:287` (a type named
by string), `rakun-session/src/session.bp:7`, `rakun-data/src/orm/query.bp:33` (method `@Decl`
params), `rakun-client/src/exchange.bp:48,78` (no JSON value model). The check the track brief
names — a grep for `// LANGUAGE GAP` over every repository, `specs/1.0.10-beta/**` excluded
(`../../02-std-and-packaging/README.md` STD-10, `../../05-jhonstart/README.md` the spec markers) —
is written as a meta-level script (`scripts/language-gap-markers.sh` in the meta repository, run by
114's meta workflow) that prints every marker and fails when one has no row in this milestone's
`../../language-gaps.md` (matched by file path). This front writes the five rows' *stubs* (file,
line, the note's text, owner `01-compiler`) so the check is green at landing; the rows' substance
is `../../01-compiler/`'s.

**Acceptance:**
- [ ] `scripts/language-gap-markers.sh` prints the five (plus STD-10's `parallel-fetch-example.bp:31` if its copy under `specs/1.0.11-beta` carries the marker) and exits 0 with the rows present; deleting one row → exit 1 naming the marker
- [ ] the five rows in `../../language-gaps.md`, owner named

### Step 5 — verify the five repositories' guards (gate-i), read-only

For each of rakun, jhonstart, emilia, onze, erika: `.gitignore` names `*.snap.new` and
`*.snap.md.new`; the hook refuses a staged candidate; the hook refuses when the compiler is absent;
no `scripts/known-broken-examples.txt`; the guard clauses of the five `runner-standalone.sh` are
identical (`diff` of the function bodies). A repository that fails a check is reported to its
front (99, 100, 101, 108, 109) — this front does not edit it.

**Acceptance:**
- [ ] a five-row table in this README: repository · guard · hook-absent-binary · no skip list · identical clauses, all ✓

## Gate

- [ ] `zig build test` from a cold runtime cache, green (`lib-test-runner`'s suite included)
- [ ] `zig build test-libs` → `0 failed`, no ledger column, every audit `ok`
- [ ] `scripts/gate.sh --cold` green in this front's worktree with the five library checkouts at their landed tips
- [ ] `scripts/AGENTS.md`, `modules/lib-test-runner/AGENTS.md` updated in the same commit
- [ ] commit on `fix/gate-ledger-and-scripts` in `repository/botopink-lang`; no push, no merge

## Blast radius

- `../../02-std-and-packaging/98-packaging-tail` step 4 ("this front's script does not read
  `restricted-targets.txt`") and PK-1 close: there is no ledger to read or write.
- `../../04-rakun` 03r-ah is answered by gate-a; `05-jhonstart/modules.md:18,34,36` rows close.
- Each library's own CI (99, 100, 101, 108, 109 rewrote the matrices) runs
  `zig build test-libs -- --lib <m> --target <t>` for declared targets only; a workflow row on an
  excluded target now produces no cell and the row is wrong — those fronts deleted such rows.
- `115` re-measures stage 8: 35 fewer rakun cells run (the commonJS matrix no longer exists as
  cells) and 39 audit builds are added.

## Notes

- The `--json` raw mode of `test-libs.sh` (`:95-97`) stays: it is the runner's output, not a verdict.
- A member whose manifest declares a target `botopink test` cannot run (beam, wasm) has no cell
  there and no audit either — the runner reports it as it does today for the CLI's own limit,
  which is a capability gap (`tests/language/run.sh` has the same), not a tolerance.
