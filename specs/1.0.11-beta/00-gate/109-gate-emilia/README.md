# Front 109 — gate-emilia: the snapshot guard, the skip list gone, the hook that refuses

**Priority:** medium — every emilia cell is green (17 commonJS, 17 erlang, at the open and at the
landing); the repository's own gate is what carried tolerances.
**Depends on:** none. `101` (jhonstart) for the examples gate's dependency only at verification
time — emilia's CI checks out jhonstart for it (`.github/workflows/test.yml`, the
`Checkout jhonstart` step).
**Owns:** `repository/emilia/**` for the duration of the front — `.gitignore`, `scripts/git-hooks/**`,
`scripts/known-broken-examples.txt` (deleted), `.github/workflows/test.yml`, `AGENTS.md`.
**Does not touch:** `repository/botopink-lang/**`; `src/**`, `modules/**`, `examples/**` of emilia
(`../../05-emilia/` owns them — nothing there is red).

---

## Current state

Measured 2026-09-27 on the front's tree with the compiler pinned for the front (built from
botopink-lang `eec364de`), by running `botopink test --target <t>` in every member on both
targets, `botopink build` in every example, the repository's pre-commit hook end to end (three
commits went through it) and in a scratch clone outside any botopink-lang checkout, and the CI
command shape in the workflow's layout.

| Cell | Tests (each of commonJS, erlang) |
|---|---|
| `modules/emilia` · `modules/emilia-test` | 734 · 1 |
| `examples/emilia-{backgrounds,borders,card,cascade,effects,grid,layout,modifiers}` | 12 · 10 · 4 · 11 · 12 · 13 · 12 · 16 |
| `examples/emilia-{outline-ring,spacing,text-decoration,theme,transforms,transitions,typography}` | 13 · 12 · 11 · 10 · 18 · 14 · 11 |

**34/34** cells green (17 members × 2 — every manifest inherits the workspace's
`["commonJS", "erlang"]`; `emilia-test` declares no `targets`); **15/15** examples build.

Tolerances in this repository, all removed:

| Was | Where | Now |
|---|---|---|
| pre-commit warned and returned 0 when the compiler was not found (`⚠ … skipping .bp gate`; scratch clone with `PATH=/usr/bin:/bin`: exit 0) | `scripts/git-hooks/lib/runner-standalone.sh` (`locateBotopink` miss, workspace and single-package arms) | `requireBotopink` fails the gate with the way out (`zig build install` in a botopink-lang checkout, or `BOTOPINK_BIN`); scratch clone: exit 1 |
| `scripts/known-broken-examples.txt` (0 entries, 3 comment lines) and the branch of `runExamplesGate` that read it | the file and the runner | deleted; an example that does not build fails the gate; `grep -c known-broken runner-standalone.sh` = 0 |
| no `*.snap.new` guard (`grep -c snap.new` = 0 in `.gitignore` and both hook files; a staged `x.snap.new` passed the hook: exit 0) | `.gitignore`, the hook's staged-files stage | both suffixes ignored (`git status --ignored` → `!!`) and a staged one refused before any other stage (`git add -f x.snap.new` → exit 1 naming the candidate; `y.snap.md.new` the same, with and without a compiler) |
| CI: core member only (`--lib emilia`), the examples gate on the commonJS row only, `allow_fail` key + `continue-on-error` on every row | `.github/workflows/test.yml` | `botopink-lib-test --target <t>` over the whole checkout on every row (every member and every example a row), no `allow_fail` / `continue-on-error` (`grep -c "allow_fail:"` = 0), the examples and refusals gates on every row, jhonstart checked out under `botopink-lang/repository/jhonstart` (the `emilia-card` dependency) |

`scripts/git-hooks/lib/runner-standalone.sh`, `scripts/git-hooks/pre-commit` and `.gitignore`
are jhonstart's (`101`) byte for byte (`cmp` = identical), so the five libraries' guard clauses
read the same (`113` diffs them). The refusals stage the runner carries (`runRefusalsGate`,
`refusals/*/`) is empty in emilia — no `refusals/` directory — and returns before any work.

The CI command shape, in the workflow's layout (`botopink-lang/{libs,repository/emilia,repository/jhonstart}`):
`botopink-lib-test --target commonJS` → **36 passed, 0 failed, 0 skipped** (the 17 emilia rows,
15 jhonstart rows, `std`, `actions`, `routing`, `validation`); `--target erlang` → **35 passed,
0 failed, 1 skipped** (`jhonstart-dom-test`, by its manifest — 101's structural restriction).

## Steps

### Step 1 — the hook refuses (gate-i) — done

- [x] `BOTOPINK_BIN=/nonexistent scripts/git-hooks/pre-commit` (scratch clone, no compiler on
      `PATH`) → exit 1, the message names `zig build install` / `BOTOPINK_BIN`
- [x] `touch x.snap.new && git add -f x.snap.new && scripts/git-hooks/pre-commit` → exit 1 naming
      the candidate (also with a compiler present, and for `*.snap.md.new`)
- [x] `test ! -e scripts/known-broken-examples.txt`; `grep -c known-broken scripts/git-hooks/lib/runner-standalone.sh` = 0
- [x] `AGENTS.md` § Local gate and the tree describe the gate as it is

### Step 2 — CI (gate-j) — done

- [x] `grep -c "allow_fail: true" .github/workflows/test.yml` = 0 (the key and `continue-on-error`
      are gone); five rows (`commonJS`/`erlang` × ubuntu, macos; `commonJS` × windows — the
      manifests' target set; the windows row subject to gate-f); YAML parses; the command shape
      verified above. The workflow itself runs on push

## Gate

- [x] every emilia cell `pass` on both targets — 34/34 (above); every example builds — 15/15
- [x] `(cd repository/emilia && scripts/git-hooks/pre-commit)` green with the compiler built:
      2/2 members, 15/15 examples, 0 refusals
- [x] `repository/emilia/AGENTS.md` updated (tree, § Local gate, the CI paragraph); commits on
      `front/109-gate-emilia` in the emilia submodule

## What is left

| Item | Owner |
|---|---|
| `language-gaps.md:52` (**No spelling for a negative numeric enum leaf**, bites 35 · 36 · 45) is the row for the note at `repository/emilia/modules/emilia/src/tokens.bp:2194` (front 45, `Transform.Rotate.Neg`: "`Rotate { -12 }` does not parse; `-rotate-12` is `.Transform.Rotate.Neg.__12`") — the row exists but cites no file, and `113`'s check matches by path. Text to add to the row's *Bites* cell: `45 (emilia modules/emilia/src/tokens.bp:2194, Transform.Rotate.Neg)`. The note carries no literal `// LANGUAGE GAP` marker (`grep -rn "LANGUAGE GAP" modules examples` → 0 in emilia; the comment reads "the language gap is recorded rather than worked around"), so a marker grep finds it only case-insensitively; making it literal is a one-line edit of `tokens.bp` | `113` (the row), `../../05-emilia/` (`tokens.bp`) |
| `botopink-lib-test` has no workspace selector (`--lib` takes one project name), so "every member a row" in CI is the whole checkout — `std`, the bundled libs and jhonstart's members ride along | `113` / `115` (`modules/lib-test-runner/**`) |
| The workflow's first green run on the pushed branch | the landing |

## Blast radius

- None on `../../05-emilia/` sources. The five repositories share the same
  `runner-standalone.sh` text — 99, 100, 101, 108 make the same edit in their repository;
  113 verifies all five are identical in the guard clauses (`diff` of the function bodies).
