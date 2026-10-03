# Front 98 — packaging tail: the rule checked across the seven repositories

**Priority:** medium — closes `02-packaging` steps 3 and 4 and front 95; nothing compiles
differently when it lands, but the gate cannot claim the packaging rule holds until it does
**Depends on:** the library tracks' `-test` and example-README steps (`05-jhonstart/26` step 6,
`06-emilia/33` steps 1–2, `07-onze/50` step 8 and `53` step 1, the `04-rakun` track's `rakun-test`
front) · maintainer decisions `95-f` (the takeover as it is) and `lg2-v` (step 4) · `00-gate` for
PK-1 and PK-5
**Owns:** `repository/erika/modules/erika-test/**`, `repository/erika/examples/erika-linq/README.md`,
`repository/erika/AGENTS.md` (erika has no track this milestone) ·
`repository/botopink-lang/docs/botopink-json.md` · by the decision-75 carve-out, and only under
step 4: `repository/botopink-lang/modules/manifest/**`, `bpmp/src/manifest.zig`, the
`manifest.scanRoots` call sites named in the 1.0.10 `02-packaging` README · this directory
**Does not touch:** any `examples/*/README.md` or `modules/<lib>-test/**` of rakun, jhonstart,
emilia, onze (their tracks write them; this front greps them) · `libs/**` (97) ·
`scripts/restricted-targets.txt`, `scripts/known-red-libs.txt`, `scripts/test-libs.sh`, `.gitignore`,
the hooks (`00-gate`) · `compiler-core/**`, `compiler-cli/**` beyond the named call sites
**Carried from 1.0.10:** `02-packaging/README.md` § Step 3 (examples become members: `README.md`,
`git` dependencies) · § Step 4 (`<lib>-test` filled) · `02-packaging/95-ecosystem-package-restructure/README.md`
§ Step 2 (the takeover — as a confirmation) · `language-gaps.md` toolchain row "`DepSpec` has no
subdirectory field" (lg2-v) · `02-packaging/README.md` § 5 (the `-test` contract, copied here as
[`test-helpers.md`](./test-helpers.md) from `01-std/snapshots.md`)

---

## Problem

`02-packaging` states one rule for every library — a workspace, a core, a `-test` member with
`assert<Subject>(loc, …)` helpers, examples that are members with a `README.md` — and 1.0.10
verified it library by library as each moved. Measured on the trees now (`find`, `grep`):

| Rule | Holds | Does not |
|---|---|---|
| every library is a workspace; every member lists `files` | all five | — |
| every library has a `-test` member with one inline test | all five | — |
| the `-test` member exposes at least one `assert<Subject>(loc, …) -> @Result<void, string>` | jhonstart (11 helper files), onze (`core.bp`: 4) | **emilia** (`root.bp` only), **rakun** (`expect*` booleans only), **erika** (empty) |
| every example carries a `README.md` naming the upstream section and the front | onze `examples/README.md` (directory-level, not per example) | **30 of 31**: 15 emilia, 8 jhonstart, 3 rakun, 2 onze, 1 erika |
| no example depends on an ecosystem library by `git` | all | — |
| a monorepo member is installable from git | — | `DepSpec` has no subdirectory field (lg2-v); rakun front 73's starters cannot ship |

## Current state

The helpers and READMEs are written by the fronts that own the files (emilia 33, jhonstart 26,
onze 50 and 53, rakun's `-test` front). This front owns the two erika files nobody else does, the
manifest document, the conditional `subdir` field, and the check.

## Mechanism

The rule is checkable by three greps and one build, which is what this front turns into a script
the gate can run: (1) `find repository/*/examples -maxdepth 2 -name README.md` counts equal
`botopink.json` counts; (2) every `modules/*-test/src/*.bp` holds at least one
`pub fn assert[A-Z][A-Za-z]*(loc: SourceLocation` whose body hands `loc` to `snapshots.`; (3) no
`examples/*/botopink.json` carries `"git"` naming `rakun`, `jhonstart`, `emilia`, `onze` or
`erika`; (4) `zig build test-libs` lists every member.

## Steps

### Step 1 — `erika-test`'s first helper and `erika-linq`'s README

`modules/erika-test/src/asserts.bp`: `assertRows(loc: SourceLocation, q: Query<T>) ->
@Result<void, string>` rendering `q.toArray()` one row per line through `snapshots.assertAs(loc,
"rows", text)`; `test/asserts_test.bp` with one accepted snapshot per target-shared file.
`examples/erika-linq/README.md` names the LINQ operators it mirrors and that erika has no front
this milestone.

**Acceptance:**
- [ ] `zig build test-libs` reads `erika-test · commonJS: pass` and `erika-test · erlang: pass` with
      2 tests; `examples/erika-linq/test/__snapshots__/` is absent (the example's own tests are
      inline)
- [ ] `repository/erika/AGENTS.md` names the helper

### Step 2 — the packaging check, as a script

`repository/botopink-lang/scripts/check-packaging.sh` (new; the gate track decides whether
`gate.sh` calls it): the four checks of § Mechanism over `repository/*`, exit non-zero naming each
failing path.

**Acceptance:**
- [ ] run in the main checkout after the library tracks' steps land: exit 0; run with one README
      removed: exit 1 naming it; with one `-test` member emptied: exit 1 naming it
- [ ] `docs/botopink-json.md` § Examples states the README rule and the helper rule and links the
      script

### Step 3 — front 95 closed as a confirmation

Under `95-f` (1): the record's step-2 boxes close on tick — `.gitmodules` one entry, the
workspace named `onze`, eight members with `files`, `zig build test-libs` listing them (with the
`00-gate` ledger lines). Nothing to write but the `docs/botopink-json.md` line that says the
orchestrator repository carries the mocking library as tagged history.

**Acceptance:**
- [ ] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says so in one line

### Step 4 — conditional on `lg2-v`: the `subdir` field

Only if the maintainer answers `lg2-v` (2): `DepSpec` gains `subdir` on the `git` form,
refused without `git`, refused when it escapes the clone (`..`, absolute), resolved by `bpmp
install` into `.botopinkbuild/deps/<name>/` from `<clone>/<subdir>`; the compiler resolves by name
as before. Under (1) — the recommendation — the row is closed as by design and rakun front 73 ships
its starters by `path`.

**Acceptance:**
- [ ] under (2): `modules/manifest` unit tests for the three refusals; `bpmp install` of a
      fixture repository with a `subdir` lands the member; `docs/botopink-json.md` documents it
- [ ] under (1): `docs/botopink-json.md` § dependencies says a git dependency is a repository root

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree (step 4 only
      touches the compiler repository)
- [ ] `zig build test-libs` green; `scripts/check-packaging.sh` exit 0 in the main checkout
- [ ] `AGENTS.md` of every directory touched, updated in the same commit
- [ ] Commit on `fix/98-packaging-tail`; no push, no merge — landing is the maintainer's step

## Blast radius

None in behaviour. Step 4 under (2) adds a manifest field every reader parses; the located-error
table of `docs/botopink-json.md` gains three lines.

## Notes

- erika is handled here because it has no track and the rule is per library, not per track.
- The three onze ledger lines and the formatter drift are the gate's (`../README.md` § Handed to
  00-gate); this front's script does not read `restricted-targets.txt`.
