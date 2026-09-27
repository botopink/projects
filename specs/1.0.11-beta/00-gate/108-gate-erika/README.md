# Front 108 — gate-erika: `erika-linq` widened, two dead CI rows gone, the repository's own gate hard

**Priority:** medium — every erika cell was green; what was wrong was one restriction that
restricted nothing and a CI matrix with two rows that measured nothing.
**Depends on:** none to start. `113` lands after it (the `erika-linq erlang 0` line goes with the
file).
**Owns:** `repository/erika/**` for the duration of the front — `examples/erika-linq/botopink.json`,
`.github/workflows/test.yml`, `.gitignore`, `scripts/git-hooks/**`.
**Does not touch:** `repository/botopink-lang/**` (`scripts/restricted-targets.txt` is 113's; the
erlang emitter's imported-method-owner fix the ledger line credits is landed and is not re-opened
here); `src/**` of `erika` beyond what a green cell needs (`../../01-compiler/09-ecosystem-residuals`
keeps the tree).

---

## Current state

Measured 2026-09-27 on the front's tree with the compiler pinned for the front (botopink-lang
`eec364de`), by running `botopink test --target <t>` in every member on every target its manifest
declares, `botopink build --target <t>` in the example, the repository's pre-commit hook end to
end, and `botopink-lib-test --target <t>` (the CI step's command) with the front's `repository/`
as the runner's only root.

| Cell | Manifest | commonJS | erlang |
|---|---|---|---|
| `erika` (`modules/erika`) | no `targets` | 31/31 | 31/31 |
| `erika-test` (`modules/erika-test`) | no `targets` | 1/1 | 1/1 |
| `erika-linq` (`examples/erika-linq`) | no `targets` — was `["commonJS"]` | 9/9 | 9/9 (9/9 before the edit too) |

**6/6 cells green** (the milestone's open counted 5 and one restricted at `0`; the restricted one
is a cell now). `botopink build` of the example exits 0 on both targets (3 files on commonJS, 10
on erlang). Pre-commit: 2/2 members, 1/1 example.

Tolerances in this repository, all removed:

| Was | Where | Now |
|---|---|---|
| `"targets": ["commonJS"]` on a cell that passes on erlang | `examples/erika-linq/botopink.json` | deleted (gate-a / gate-d: a restriction with no host reason is deleted); 9/9 on erlang measured before and after |
| two `beam` CI rows — `botopink test` cannot run beam, the runner printed `skipped` and the row passed | `.github/workflows/test.yml` | deleted; `grep -c "target: beam"` = 0. A `beam` row returns when a library cell can run there (`111`) |
| `allow_fail` key on every row, `continue-on-error` on the job | same file | both keys gone (`grep -c allow_fail:` = 0); every row hard |
| CI tested the core member only (`--lib erika`), examples on the commonJS row | same file | `botopink-lib-test --target <t>` over the whole checkout on every row (every member and every example a row; `--lib erika` selects the core member only, so the workspace is one call without it and `std` rides along — the runner has no workspace selector); the examples and refusals gates on every row |
| pre-commit warned and returned 0 when the compiler was not found | `scripts/git-hooks/lib/runner-standalone.sh` | `requireBotopink` fails the gate with the way out (`zig build install`, or `BOTOPINK_BIN`); verified in a scratch repository: hook exit 1, `git commit` exit 1 |
| `scripts/known-broken-examples.txt` branch of `runExamplesGate` | same file | deleted; an example that does not build fails |
| no `*.snap.new` guard | `.gitignore`, the hook's staged-files stage | both suffixes ignored and a staged one refused (`git add -f x.snap.new y.snap.md.new` → exit 1, verified); `grep -c snap.new` → 1 and 5 |

`scripts/git-hooks/lib/runner-standalone.sh`, `scripts/git-hooks/pre-commit` and `.gitignore`
are byte-identical to jhonstart's (101's landing), refusals stage included (a no-op until erika
has a `refusals/` case); `.github/workflows/test.yml` differs from jhonstart's in `LIB_NAME` and
the absent emilia-checkout step only. The matrix is the manifests' target set: no member narrows
`targets`, so `{ubuntu-22.04, macos-14} × {commonJS, erlang}` + `windows-2022 × commonJS`.

## Steps

### Step 1 — widen `erika-linq` — done

- [x] `botopink test --target erlang` in the example → 9 passed, 0 failed; commonJS unchanged (9/9)
- [x] until 113 lands, `zig build test-libs` reports `restricted-targets.txt`'s `erika-linq erlang 0`
      line as stale — expected; 113 deletes the file. The front's own gate is `botopink test` per member

### Step 2 — the repository's own gate: hook, guard, CI (gate-i, gate-j) — done

- [x] `grep -c "target: beam" .github/workflows/test.yml` = 0; `grep -c "allow_fail: true"` = 0 (the key is gone)
- [x] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` → 1 and 5; the hook without a
      compiler binary → exit 1 with the build hint; a staged `x.snap.new` → exit 1
- [x] the CI command shape verified with the front's `repository/` as the only root:
      `botopink-lib-test --target commonJS` lists `erika`, `erika-linq`, `erika-test` as passing rows
      (37 passed, 5 failed, 38 skipped over the root — the reds are rakun's and onze's, fronts 99 and 100);
      on erlang the whole-root run exceeds 15 minutes (rakun's erlang cells), so each erika row was
      measured by name — `--lib erika` 31/0, `--lib erika-test` 1/0, `--lib erika-linq` 9/0, each
      `1 passed, 0 skipped` (the widened example is a row, not a skip)

## Gate

- [x] every erika cell `pass` on commonJS and erlang — 6/6 (above)
- [x] `(cd repository/erika && scripts/git-hooks/pre-commit)` green; the workflow's command shape verified as
      in step 2 (the workflow itself runs on push)
- [x] `repository/erika/AGENTS.md` updated; commits on `front/108-gate-erika` in the erika submodule

## What is left

| Item | Owner |
|---|---|
| `restricted-targets.txt`'s `erika-linq erlang 0` line is stale (the cell runs) | `113` (deletes the file) |
| `botopink-lib-test` has no workspace selector, so "every member a row" in CI is the whole checkout (`std` rides along) | `113` / `115` (`modules/lib-test-runner/**`) — 101 filed the same row |

## Blast radius

- `113` deletes the `erika-linq erlang 0` line with the file; `../../01-compiler/carried.md` RT-1 and
  `09-ecosystem-residuals`' "lift erika-linq targets" row close on this landing.
- No other track owns erika files this milestone. Emilia's and onze's `runner-standalone.sh` are
  the file erika's was before this front; 109 and 100 land the same copy.
