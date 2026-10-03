# Front 98 — packaging tail: the rule checked across the seven repositories

**Priority:** medium — nothing compiles differently when it lands, but no one can claim the
packaging rule holds until it does · **State:** not started
**Depends on:** the library tracks' `-test` and example-README steps (`05-jhonstart/26` step 6,
`06-emilia/33` steps 1–2, `07-onze/50` step 8 and `53` step 1, the `04-rakun` track's `rakun-test`
front — `19-rakun-test-utilities`) · `95-f` (step 3) · `lg2-v` (step 4)
**Owns:** `repository/erika/modules/erika-test/**`, `repository/erika/examples/erika-linq/README.md`,
`repository/erika/AGENTS.md` (erika has no track this milestone) ·
`repository/botopink-lang/scripts/check-packaging.sh` (new) ·
`repository/botopink-lang/docs/botopink-json.md` · by the decision-75 carve-out, and only under
step 4: `repository/botopink-lang/modules/manifest/**`, `bpmp/src/manifest.zig`, the
`manifest.scanRoots` call sites named in the 1.0.10 `02-packaging` README · this directory
**Does not touch:** any `examples/*/README.md` or `modules/<lib>-test/**` of rakun, jhonstart,
emilia, onze (their tracks write them; this front greps them) · `libs/**` (97) ·
`scripts/test-libs.sh`, `.gitignore`, the hooks · `compiler-core/**`, `compiler-cli/**` beyond the
named call sites

## Goal

Every library is a workspace with a core, a `-test` member exposing `assert<Subject>(loc, …)`
helpers (the contract: [`test-helpers.md`](./test-helpers.md)), and examples that are members with
a `README.md`; a script proves it across `repository/*`, and the onze takeover and the git
subdirectory question are closed.

Measured on feat:

| Rule | Holds | Does not |
|---|---|---|
| every library is a workspace; every member lists `files` | all five | — |
| every library has a `-test` member with one inline test | all five | — |
| the `-test` member exposes at least one `assert<Subject>(loc, …) -> @Result<void, string>` | jhonstart (11 helper files), onze (`core.bp`: 4) | **emilia** (`root.bp` only), **rakun** (`expect*` booleans only), **erika** (`src/root.bp` only, no `test/`) |
| every example carries a `README.md` naming the upstream section and the front | — (onze has one directory-level `examples/README.md`) | **29 of 29** |
| no example depends on an ecosystem library by `git` | all | — |
| a monorepo member is installable from git | — | `DepSpec` has no subdirectory field (lg2-v); rakun front 73's starters cannot ship |

## Mechanism

The rule is four checks, which step 2 turns into a script: (1) `find repository/*/examples
-maxdepth 2 -name README.md` counts equal `botopink.json` counts; (2) every `modules/*-test/src/*.bp`
holds at least one `pub fn assert[A-Z][A-Za-z]*(loc: SourceLocation` whose body hands `loc` to
`snapshots.`; (3) no `examples/*/botopink.json` carries `"git"` naming `rakun`, `jhonstart`,
`emilia`, `onze` or `erika`; (4) `zig build test-libs` lists every member.

## Open

### Step 1 — `erika-test`'s first helper and `erika-linq`'s README

`modules/erika-test/src/asserts.bp`: `assertRows(loc: SourceLocation, q: Query<T>) ->
@Result<void, string>` rendering `q.toArray()` one row per line through `snapshots.assertAs(loc,
"rows", text)`; `test/asserts_test.bp` with one accepted snapshot per target-shared file.
`examples/erika-linq/README.md` names the LINQ operators it mirrors and that erika has no front
this milestone.

- [ ] `zig build test-libs` reads `erika-test · commonJS: pass` and `erika-test · erlang: pass` with
      2 tests; `examples/erika-linq/test/__snapshots__/` is absent (the example's own tests are
      inline)
- [ ] `repository/erika/AGENTS.md` names the helper

### Step 2 — the packaging check, as a script

`repository/botopink-lang/scripts/check-packaging.sh`: the four checks of § Mechanism over
`repository/*`, exit non-zero naming each failing path. Whether `gate.sh` calls it is the gate's
call.

- [ ] run in the main checkout after the library tracks' steps land: exit 0; with one README
      removed: exit 1 naming it; with one `-test` member emptied: exit 1 naming it
- [ ] `docs/botopink-json.md` § Examples states the README rule and the helper rule and links the
      script

### Step 3 — front 95 closed as a confirmation

Under `95-f` (1): `.gitmodules` has one `repository/onze` entry, the workspace is named `onze`,
eight members with `files`, `zig build test-libs` lists them. `git -C repository/onze rev-parse
mocking-lib-final` already resolves. Nothing to write but the line in `docs/botopink-json.md`.

- [ ] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says in one line that
      the orchestrator repository carries the mocking library as tagged history

### Step 4 — conditional on `lg2-v`: the `subdir` field

Under (2): `DepSpec` gains `subdir` on the `git` form, refused without `git`, refused when it
escapes the clone (`..`, absolute), resolved by `bpmp install` into `.botopinkbuild/deps/<name>/`
from `<clone>/<subdir>`; the compiler resolves by name as before. Under (1) — the recommendation —
the row is closed as by design and rakun front 73 ships its starters by `path`.

- [ ] under (2): `modules/manifest` unit tests for the three refusals; `bpmp install` of a
      fixture repository with a `subdir` lands the member; `docs/botopink-json.md` documents it
      (three lines in its located-error table)
- [ ] under (1): `docs/botopink-json.md` § dependencies says a git dependency is a repository root

## Decisions

`95-f`, `lg2-v` — [`../README.md`](../README.md) § Decisions.

**Gate:** standard (fronts.md § Gate) + `scripts/check-packaging.sh` exit 0 in the main checkout
