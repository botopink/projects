# Front 98 — packaging tail: the rule checked across the seven repositories

**Priority:** medium — compiles nothing differently; the packaging rule holds only once it lands ·
**State:** not started
**Depends on:** the library tracks' `-test` and example-README steps (`05-jhonstart/26` step 6,
`06-emilia/33` steps 1–2, `07-onze/50` step 8 and `53` step 1, `04-rakun`'s `rakun-test` front
`19-rakun-test-utilities`) · `95-f` (step 3)
**Owns:** `repository/erika/modules/erika-test/**`, `repository/erika/examples/erika-linq/README.md`,
`repository/erika/AGENTS.md` (erika has no track) · `repository/botopink-lang/scripts/check-packaging.sh`
(new) · `repository/botopink-lang/docs/botopink-json.md` · decision-75 carve-out, step 4 only:
`repository/botopink-lang/modules/manifest/**`, `bpmp/src/manifest.zig`, the `manifest.scanRoots`
call sites named in the 1.0.10 `02-packaging` README · this directory
**Does not touch:** `examples/*/README.md` or `modules/<lib>-test/**` of rakun, jhonstart, emilia,
onze (their tracks write, this front greps) · `libs/**` (97) · `scripts/test-libs.sh`, `.gitignore`,
the hooks · `compiler-core/**`, `compiler-cli/**` beyond the named call sites

## Goal

Every library: a workspace with a core, a `-test` member exposing `assert<Subject>(loc, …)` helpers
(contract: [`test-helpers.md`](./test-helpers.md)), examples as members with a `README.md`; a script
proves it across `repository/*`; the onze takeover and git-subdirectory question closed.

Measured on feat:

| Rule | Holds | Does not |
|---|---|---|
| every library is a workspace; every member lists `files` | all five | — |
| every library has a `-test` member with one inline test | all five | — |
| the `-test` member exposes ≥ one `assert<Subject>(loc, …) -> @Result<void, string>` | jhonstart (11 helper files), onze (`core.bp`: 4) | **emilia** (`root.bp` only), **rakun** (`expect*` booleans only), **erika** (`src/root.bp` only, no `test/`) |
| every example carries a `README.md` naming the upstream section and the front | — (onze: one directory-level `examples/README.md`) | **29 of 29** |
| no example depends on an ecosystem library by `git` | all | — |
| a monorepo member is installable from git | — | `DepSpec` has no subdirectory field (step 4, decision 344); rakun front 73's starters cannot ship |

## Mechanism

Four checks (step 2's script):
1. `find repository/*/examples -maxdepth 2 -name README.md` count = `botopink.json` count;
2. every `modules/*-test/src/*.bp` holds ≥ one `pub fn assert[A-Z][A-Za-z]*(loc: SourceLocation`
   whose body hands `loc` to `snapshots.`;
3. no `examples/*/botopink.json` carries `"git"` naming `rakun`, `jhonstart`, `emilia`, `onze`, `erika`;
4. `zig build test-libs` lists every member.

## Open

### Step 1 — `erika-test`'s first helper and `erika-linq`'s README

`modules/erika-test/src/asserts.bp`: `assertRows(loc: SourceLocation, q: Query<T>) ->
@Result<void, string>`, `q.toArray()` one row per line through `snapshots.assertAs(loc, "rows",
text)`; `test/asserts_test.bp`, one accepted snapshot per target-shared file.
`examples/erika-linq/README.md`: the LINQ operators it mirrors; erika has no front this milestone.

- [ ] `zig build test-libs` reads `erika-test · commonJS: pass` and `erika-test · erlang: pass` with
      2 tests; `examples/erika-linq/test/__snapshots__/` absent (example tests are inline)
- [ ] `repository/erika/AGENTS.md` names the helper

### Step 2 — the packaging check, as a script

`repository/botopink-lang/scripts/check-packaging.sh`: § Mechanism's four checks over
`repository/*`, non-zero exit naming each failing path. Calling it from `gate.sh` is the gate's call.

- [ ] main checkout after the library steps land: exit 0; one README removed: exit 1 naming it; one
      `-test` member emptied: exit 1 naming it
- [ ] `docs/botopink-json.md` § Examples states the README and helper rules, links the script

### Step 3 — front 95 closed as a confirmation

Under `95-f` (1): one `repository/onze` entry in `.gitmodules`, workspace `onze`, eight members with
`files`, listed by `zig build test-libs`; `mocking-lib-final` already resolves. Only the
`docs/botopink-json.md` line to write.

- [ ] `git -C repository/onze rev-parse mocking-lib-final` resolves; `git submodule status
      repository/onze` is the orchestrator's commit; `docs/botopink-json.md` says in one line the
      orchestrator repository carries the mocking library as tagged history

### Step 4 — the `subdir` field (decision 344)

`DepSpec` gains `subdir` on the `git` form — refused without `git`, refused escaping the clone (`..`,
absolute); `bpmp install` resolves `<clone>/<subdir>` into `.botopinkbuild/deps/<name>/`, the
member's `path` dependencies inside the same clone (`01-compiler/26` step 6, the resolver half);
compiler resolves by name as before.

- [ ] `modules/manifest` unit tests for the refusals (`subdir` without `git`; absolute or `..`);
      `bpmp install` of a fixture repository with a `subdir` lands the member and its sibling at the
      same `ref`; `docs/botopink-json.md` documents the field and its located errors

## Decisions

`95-f` — [`../README.md`](../README.md) § Decisions; `subdir` is decision 344.

**Gate:** standard (fronts.md § Gate) + `scripts/check-packaging.sh` exit 0 in the main checkout
