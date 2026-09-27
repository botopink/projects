# Front 108 — gate-erika: `erika-linq` widened, two dead CI rows gone, the repository's own gate hard

**Priority:** medium — every erika cell is green; what is wrong is one restriction that restricts
nothing and a CI matrix with two rows that measure nothing.
**Depends on:** none to start. `113` lands after it (the `erika-linq erlang 0` line goes with the
file).
**Owns:** `repository/erika/**` for the duration of the front — `examples/erika-linq/botopink.json:8`,
`.github/workflows/test.yml`, `.gitignore`, `scripts/git-hooks/**`.
**Does not touch:** `repository/botopink-lang/**` (`scripts/restricted-targets.txt` is 113's; the
erlang emitter's imported-method-owner fix the ledger line credits is landed and is not re-opened
here); `src/**` of `erika` beyond what a green cell needs (`../../01-compiler/09-ecosystem-residuals`
keeps the tree).

---

## Problem

```
$ cd repository/botopink-lang && zig build test-libs -- --lib erika-linq --target erlang
── erika-linq · erlang: restricted — 0 failed, as pinned (00/09-ecosystem-residuals `"targets": ["commonJS"]`; the erlang row is green today — 9 pass, 0 fail …)
```

Measured at the open: `erika` 3 pass / 3 pass, `erika-linq` commonJS pass, erlang restricted at `0`
(`scripts/restricted-targets.txt:58`). The ledger line's own text says the restriction outlived its
reason (the 8 reds were one compiler defect, fixed). The repository's own gate (report L): **green,
100 %** — 5/5 cells (`erika` 31/0, `erika-test` 1/0, `erika-linq` commonJS 9/0); pre-commit 2/2
members, 1/1 example; CI tests the core member only (`--lib erika`), which gate-j's step below
widens to every member.

## Current state

| Tolerance | Where | Decision |
|---|---|---|
| `"targets": ["commonJS"]` on a cell that passes on erlang | `examples/erika-linq/botopink.json:8` | gate-a / gate-d — a restriction with no host reason is deleted |
| two `beam` CI rows: `zig build test-libs -- --lib erika --target beam` — `botopink test` cannot run beam, the runner prints `skipped` and the row passes | `.github/workflows/test.yml:45,48` | gate-j |
| pre-commit warns and skips when the compiler is not found; `known-broken-examples.txt` branch | `scripts/git-hooks/lib/runner-standalone.sh` | gate-i |
| no `*.snap.new` guard | `.gitignore`, `scripts/git-hooks/pre-commit` | gate-i |

## Mechanism

`lib-test-runner/src/main.zig:225-235`: a target the manifest excludes is `.skipped`
(`skipped_unsupported`), "never fails the run (even under --strict)"; a target `botopink test`
cannot run at all is the same status from the CLI side (`test-libs.sh:312-315` "skipped — `botopink
test` cannot run this target"). A CI row on such a target is green by construction.

## Steps

### Step 1 — widen `erika-linq`

Delete the `"targets"` line in `examples/erika-linq/botopink.json`; run the cell on both targets.

**Acceptance:**
- [ ] `zig build test-libs -- --lib erika-linq --target erlang` → `pass` (9 tests); commonJS unchanged
- [ ] until 113 lands the full run reports the line as stale — expected

### Step 2 — the repository's own gate: hook, guard, CI (gate-i, gate-j)

- `.gitignore` + hook: `*.snap.new` / `*.snap.md.new` refused; `locateBotopink` miss → fail; the
  `known-broken-examples.txt` branch deleted.
- `.github/workflows/test.yml`: delete the two `beam` rows (`:45,48`) — a `beam` row returns when a
  library cell can run there (`111` makes `run.sh` include beam for the language tests; `botopink
  test` on beam is not this milestone's); the remaining rows stay hard; the test step runs every
  member (`erika`, `erika-test`, `erika-linq` — the runner's discovery from the root, not
  `--lib erika`); the examples gate on every row.

**Acceptance:**
- [ ] `grep -c "target: beam" .github/workflows/test.yml` = 0; `grep -c "allow_fail: true"` = 0
- [ ] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` ≥ 1 each; the hook without a compiler binary → exit 1

## Gate

- [ ] `zig build test-libs -- --lib erika` and `-- --lib erika-linq` on commonJS and erlang → `pass`
- [ ] `(cd repository/erika && scripts/git-hooks/pre-commit)` green; the workflow green
- [ ] `repository/erika/AGENTS.md` updated; commit on `front/gate-erika` in the erika submodule; no push, no merge

## Blast radius

- `113` deletes `restricted-targets.txt:58` with the file; `../../01-compiler/carried.md` RT-1 and
  `09-ecosystem-residuals`' "lift erika-linq targets" row close on this landing.
- No other track owns erika files this milestone.
