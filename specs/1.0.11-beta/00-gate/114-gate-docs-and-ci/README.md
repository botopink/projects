# Front 114 — gate-docs-and-ci: no `skip` fence, no soft CI row, the meta workflow measured

**Priority:** high — stage 10 was green with 8 of 93 fences unchecked, two of them claims about
refusals that nothing verified; the compiler's CI had a row that could not fail; the meta
repository's hook-integrity workflow did not exist at the open.
**Depends on:** none — group D, independent files. `115` measures stage 10 after it.
**Owns:** `scripts/check-docs.sh` · the marker lines of `docs.md` and the fence lines after them
(a fence language change, a `project` manifest fence, a refusal fence's own code — no prose edit:
`docs.md`'s text is `../../01-compiler/08-hygiene`'s) · `.github/workflows/test.yml` of
botopink-lang (the `test` job's rows and the erika checkout its `test-docs` step needs; the `libs`
job comment is 113's) · the meta repository's `.github/workflows/**` and its `AGENTS.md` § CI ·
the snapshot-capture normalisation for windows (not measured — see step 3).
**Does not touch:** `docs.md` prose; `README.md`'s one fence (green); the library repositories'
workflows (99–109's); `scripts/gate.sh` (115's); `build.zig`.

---

## Current state

```
$ bash scripts/check-docs.sh
self-test: 9 fences — 9 verdicts as expected
…
docs: 94 fences — 94 checked, 0 skipped, 0 failed      # was 93 — 77 checked, 8 skipped at the open
```

Measured in this front's worktree, botopink-lang at the `feat` tip plus this front's tree. The
count moved by −3 (three tables are ```` ```text ````), +3 (`:1765` split into four `reject`
fences) and +1 (the `project` manifest fence); `checked` now counts every fence — a project's
verdict is credited to each fence written into it, so `checked + failed = fences` (at the open the
eleven project files counted as three checks, which is why `77 + 8 ≠ 93`).

| Marker (at the open) | Now | Verdict |
|---|---|---|
| `:223` `import {of, erika} from "erika"` | `project library src/main.bp` + a ```` ```json ```` fence `project library botopink.json` declaring `"erika": { "git": …, "branch": "feat" }` — resolved **by name** through the roots the harness sets (`libs/`, `<repo>/..`, `<repo>/repository`), no path rewrite | ✓ (3 modules) |
| `:235` bundled imports | a plain module fence, no marker — the bundled packages resolve by name | ✓ (23 modules) |
| `:684` literal table · `:773` operator table · `:809` layout sample | ```` ```text ````, no marker | not code |
| `:736` the two ambient behaviors | a plain module fence, no marker — they type-check | ✓ |
| `:1137` grammar | the fence had no language; the marker is gone | not code |
| `:1351` `connect();` | `reject 'connect' expects 2 argument(s), got 0`; the call sits in `fn main() { … }` — a module-level statement is a parse error and a nested `fn` is `nested-fn-decl`, so neither the bare fence nor `body` reaches the arity check | ✓ refused |
| `:1765` four refusals | four `reject` fences (`effect-try-without-fallible-channel`, `iter-await`, `iter-mixed-yield-return`, `iterator-error-param-removed`); `old()` has the body `{ yield 0; }` — `…` was a lexer error, which is not the claim | ✓ refused, each |

`check-docs.sh`: `reject [body] <expectation>` — the rest of the comment, verbatim, must appear in
the first `error` line of a non-zero `botopink check`; the two diagnostic shapes the compiler
prints (`error[<id>]: …` and `error: <id>: …`) both carry it. One refusal per fence: the checker
stops at the first failing module (measured: two refusing functions in one module print one
diagnostic). `skip` is gone; a directive on a non-`botopink` fence (`project` excepted), a `reject`
with no expectation and an unknown directive fail. Every run judges nine synthetic fences first
(`--self-test` runs only them): a `reject` that compiles ✗, refused with another diagnostic ✗, the
right one ✓, `reject body` ✓, `skip` ✗, a red module ✗, a green one ✓, `reject` with no
expectation ✗, `body` on a ```` ```text ```` fence ✗.

CI (`.github/workflows/test.yml`): `allow_fail` and `continue-on-error` are gone; the matrix is
`[ubuntu-22.04, macos-14]` and every row runs every step (`beam export audit` and `test-language`
no longer conditional). The `test` job checks out erika under `repository/erika` before
`test-docs` — the docs' `project` fence resolves it there, as the `libs` job's layout does.

The meta repository: `.github/workflows/hook-integrity.yml`, one job on push/PR to `feat`/`main`,
checkout with submodules, five hard checks in plain bash (each runnable locally from the meta root
— the meta `AGENTS.md` § CI lists them). Run against this front's worktree:

| Check | Local result |
|---|---|
| 1 every submodule pointer on its remote `feat` | ✓ ×7 · a pointer moved to a dangling commit → ✗ |
| 2 every § Layout path exists (first backticked path per row, `{a,b}` expanded, the git-ignored `todo.md` row excluded) | ✓ ×13 · `CHANGELOG.md` moved away → ✗ |
| 3 no tracked `*.snap.new` / `*.snap.md.new` / `todo.md` (meta + 7 submodules) | ✓ ×8 · a `git add -f x.snap.new` → ✗ |
| 4 the five libraries' `pre-commit` + `runner-standalone.sh` byte-identical (jhonstart the reference), `.gitignore` names both candidate patterns, no `known-broken-examples.txt`, `AGENTS.md` names `core.hooksPath` | erika ✓; **emilia** (runner, `.gitignore`, `known-broken-examples.txt`) → 109; **onze** (runner, `.gitignore`) → 100; **rakun** (runner, `.gitignore`) → 99 |
| 5 `scripts/language-gap-markers.sh` exits 0 | the script does not exist yet → 113 step 4c |

Checks 4 and 5 go green when 99, 100, 109 and 113 land; nothing here is soft meanwhile.

## Steps

### Step 1 — `reject` and `project` replace `skip` (gate-e) — done

- [x] `bash scripts/check-docs.sh` → `docs: 94 fences — 94 checked, 0 skipped, 0 failed`
- [x] `grep -c "docs-check: skip" docs.md README.md` = 0; `grep -c '"skip"\|skip)' scripts/check-docs.sh` = 0
- [x] the harness's self-test (nine synthetic fences, run first on every run; `--self-test`)
- [x] `--list` prints `reject` for the five refusal fences and `project library …` for the two files

### Step 2 — `scripts/AGENTS.md` § check-docs.sh — done

- [x] the directive table: `reject` added, `skip` gone; `grep -c "only escape" scripts/AGENTS.md AGENTS.md` = 0

### Step 3 — the windows row is hard or absent (gate-f) — the row is deleted

The drift was not measured: no windows runner or checkout was available to this front, and a
normalisation of `helpers.zig`'s capture that no run verified would be a snapshot re-recorded for
a value nobody saw. Under gate-f's recommendation the row is deleted, not soft; `../../status.md`
lists the gap. What remains: run the `test` job's steps on a windows runner, list the failing
snapshot tests by cause (CRLF in captured stdout; `\` in captured paths); if the capture can be
normalised in `modules/compiler-core/src/codegen/tests/helpers.zig` without touching an emitter,
do it and restore the row hard, running every stage the ubuntu row runs (OTP, node and wasmtime
install there; `erlef/setup-beam` supports windows).

- [x] `grep -c "allow_fail" .github/workflows/test.yml` = 0; `grep -c "windows-2022"` = 0
- [ ] the workflow green on `feat` after the maintainer's push

### Step 4 — the meta repository's workflow — done

- [x] `.github/workflows/hook-integrity.yml` at the meta root; the three synthetic runs fail it (table above)
- [x] the meta `AGENTS.md` names the workflow (§ Layout row) and its five checks (§ CI)
- [ ] checks 4 and 5 green on `feat` — after 99, 100, 109, 113

## Gate

- [x] `zig build test-docs` green with `0 skipped`; no Zig touched
- [ ] `scripts/gate.sh --cold` green in this front's worktree — stage 8 `test-libs` is red at the
      `feat` tip (rakun 25 cells, onze 11 cells — 99's and 100's), so the botopink-lang commits
      wait, staged, for their landing
- [x] `scripts/AGENTS.md`, the root and the meta `AGENTS.md` in the same change

## Handed out

| Item | To | Why |
|---|---|---|
| `docs.md:5` — "a fence that is not a module … says so in a `docs-check` comment" is stale: a table is ```` ```text ```` now and carries no comment | `../../01-compiler/08-hygiene` (prose) | this front edits fence and marker lines only |
| `build.zig:567-570` — the `test-docs` comment still describes the `skip` directive | `build.zig`'s owner | not this front's file |
| the windows drift measurement and the capture normalisation | carried (this README, step 3) | no windows runner in this milestone |

## Blast radius

- `../../01-compiler/08-hygiene` owns `docs.md`'s prose: this front changed fence languages,
  marker lines and the code of two refusal fences only, and lands first; 08 rebases.
- `../../01-compiler/18-comptime-runtimes` "CI matrix run test.yml (ubuntu/macos/windows)" is
  the same file: there is no windows row until step 3's measurement lands.
- 99–109's workflows are theirs; their windows rows stay hard on their own.
