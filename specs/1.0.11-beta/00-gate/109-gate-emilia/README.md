# Front 109 — gate-emilia: the snapshot guard, the skip list gone, the hook that refuses

**Priority:** medium — every emilia cell is green (17 commonJS, 17 erlang, measured at the open);
the repository's own gate is what carries tolerances.
**Depends on:** none. `101` (jhonstart) for the examples gate's dependency only at verification
time — emilia's CI checks out jhonstart for it (`.github/workflows/test.yml:136`).
**Owns:** `repository/emilia/**` for the duration of the front — `.gitignore`, `scripts/git-hooks/**`,
`scripts/known-broken-examples.txt` (deleted), `.github/workflows/test.yml`.
**Does not touch:** `repository/botopink-lang/**`; `src/**`, `modules/**`, `examples/**` of emilia
(`../../05-emilia/` owns them — nothing there is red).

---

## Problem

```
$ cd repository/emilia && BOTOPINK_BIN=/nonexistent scripts/git-hooks/pre-commit
── pre-commit ──
⚠ botopink binary not found (env BOTOPINK_BIN, ancestor zig-out/bin, or $PATH) — skipping .bp gate
$ echo $?
0
```

A commit is gated by nothing when the compiler is not on the path (`scripts/git-hooks/lib/runner-standalone.sh`,
the `locateBotopink` miss → `warn` → `return 0`). The same file reads
`scripts/known-broken-examples.txt` — a skip list (empty today: 0 lines; the only repository that
has the file). Neither `.gitignore` nor the hook names `*.snap.new` (`grep -c snap.new` = 0).
The repository's own gate (report L): **green, 100 %** — 34/34 cells (17 members × 2;
`modules/emilia` 734/0); pre-commit 2/2 members, 15/15 examples; CI tests the core member only
(`--lib emilia`) and the examples only on the commonJS row. One `// LANGUAGE GAP` note without a
row: `src/tokens.bp:2194` (a negative leaf) — `113`'s marker check lists it; the row goes to
`../../language-gaps.md`, owned by `../../01-compiler/`.

## Current state

| Tolerance | Where | Decision |
|---|---|---|
| warn-and-skip when the compiler is absent | `scripts/git-hooks/lib/runner-standalone.sh` (`locateBotopink` miss, twice: workspace and single-package arms) | gate-i |
| `scripts/known-broken-examples.txt` (0 lines) and its branch in `runExamplesGate` | the file and the runner | gate-i |
| no `*.snap.new` guard | `.gitignore`, `scripts/git-hooks/pre-commit` | gate-i (STD-1 / EM-6 in `../../02-std-and-packaging/README.md`) |
| CI rows hard already (`:43-47`, all `allow_fail: false`); the examples gate only on the commonJS row | `.github/workflows/test.yml` | gate-j |

## Steps

### Step 1 — the hook refuses (gate-i)

- `runner-standalone.sh`: `locateBotopink` miss → `fail "botopink binary not found — build
  repository/botopink-lang (zig build) or set BOTOPINK_BIN"`; the `known-broken-examples.txt`
  reading and the `known broken` verdict deleted; `scripts/known-broken-examples.txt` deleted.
- A staged `*.snap.new` / `*.snap.md.new` is refused before stage 1 (the conflict-marker scan
  already walks `git diff --cached --name-only`; add the candidate check as
  `botopink-lang/scripts/gate.sh:126-128,135` does).
- `.gitignore`: `*.snap.new`, `*.snap.md.new`.

**Acceptance:**
- [ ] `BOTOPINK_BIN=/nonexistent scripts/git-hooks/pre-commit` → exit 1, message names the fix
- [ ] `touch x.snap.new && git add -f x.snap.new && scripts/git-hooks/pre-commit` → exit 1 naming the candidate
- [ ] `test ! -e scripts/known-broken-examples.txt`; `grep -c known-broken scripts/git-hooks/lib/runner-standalone.sh` = 0

### Step 2 — CI (gate-j)

The examples gate runs on every row (it builds each example on its own manifest target); the
`Checkout jhonstart` step stays (the examples' dependency). The test step runs every member of the
workspace (17 at the open — the runner's discovery from the root, not `--lib emilia`). Rows
unchanged otherwise; the windows row subject to gate-f.

**Acceptance:**
- [ ] `grep -c "allow_fail: true" .github/workflows/test.yml` = 0; the workflow green

## Gate

- [ ] `zig build test-libs -- --lib emilia` on both targets → `pass` (and every `emilia-*` example member: `find repository/emilia/{modules,examples} -maxdepth 1 -mindepth 1 -type d`)
- [ ] `(cd repository/emilia && scripts/git-hooks/pre-commit)` green with the compiler built
- [ ] `repository/emilia/AGENTS.md` updated; commit on `front/gate-emilia` in the emilia submodule; no push, no merge

## Blast radius

- None on `../../05-emilia/` sources. The five repositories share the same
  `runner-standalone.sh` text — 99, 100, 101, 108 make the same edit in their repository; 113
  verifies all five are identical in the guard clauses (`diff` of the function bodies).
