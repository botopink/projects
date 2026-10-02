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
on erlang). Pre-commit: 6/6 cells, 2/2 example builds.

Tolerances in this repository, all removed:

| Was | Where | Now |
|---|---|---|
| `"targets": ["commonJS"]` on a cell that passes on erlang | `examples/erika-linq/botopink.json` | deleted (gate-a / gate-d: a restriction with no host reason is deleted); 9/9 on erlang measured before and after |
| two `beam` CI rows — `botopink test` cannot run beam, the runner printed `skipped` and the row passed | `.github/workflows/test.yml` | deleted; `grep -c "target: beam"` = 0. A `beam` row returns when a library cell can run there (`111`) |
| `allow_fail` key on every row, `continue-on-error` on the job; OTP on the erlang rows only; `ubuntu-22.04`; a windows row | same file | both keys gone (`grep -c allow_fail:` = 0); rows `{ubuntu-24.04, macos-14} × {commonJS, erlang}`, every row hard; Erlang/OTP 28 and Node 20 on every row (building the compiler runs `erlc`); no windows row (gate-f) |
| CI tested the core member only (`--lib erika`), examples on the commonJS row | same file | one `botopink-lib-test --target <t> --strict` per row from a scratch directory with `BOTOPINK_LIB_ROOTS` naming the repository: the workspace's three members are the rows and nothing else is (`std` does not ride along); then the hook's other stages (the example built on the row's target) from the hook's own runner |
| pre-commit warned and returned 0 when the compiler was not found; it ran a bare `botopink test` in `modules/*` — each manifest's default `target`, commonJS for all three members, so no erlang cell | `scripts/git-hooks/lib/runner-standalone.sh` | one text in the five library repositories (`sha256sum` equal ×5; the meta `hook-integrity` check 4): a missing compiler fails the gate with the way out (`zig build install`, or `BOTOPINK_BIN`; a `BOTOPINK_BIN` that is not an executable fails too) — scratch clone: hook exit 1, `git commit` exit 1; `botopink test --target <t>` in every workspace member on every target its manifest declares and `botopink build --target <t>` of the example on both — 6 cells, 2 builds |
| `scripts/known-broken-examples.txt` branch of `runExamplesGate` | same file | deleted; an example that does not build fails |
| no `*.snap.new` guard | `.gitignore`, the hook's staged-files stage | both suffixes ignored and a staged one refused (`git add -f x.snap.new y.snap.md.new` → exit 1, verified); `grep -c snap.new` → 1 and 5 |

`scripts/git-hooks/lib/runner-standalone.sh` and `scripts/git-hooks/pre-commit` are one text in
the five library repositories, refusals stage included (absent until erika has a `refusals/`
directory); `.github/workflows/test.yml` differs from jhonstart's in `LIB_NAME`, the header's
sentence about the manifests and the absent emilia-checkout step only. The rows are the
manifests' target set on the runners the compiler is gated on: no member narrows `targets`, so
`{ubuntu-24.04, macos-14} × {commonJS, erlang}`.

## Steps

### Step 1 — widen `erika-linq` — done

- [x] `botopink test --target erlang` in the example → 9 passed, 0 failed; commonJS unchanged (9/9)
- [x] until 113 lands, `zig build test-libs` reports `restricted-targets.txt`'s `erika-linq erlang 0`
      line as stale — expected; 113 deletes the file. The front's own gate is `botopink test` per member

### Step 2 — the repository's own gate: hook, guard, CI (gate-i, gate-j) — done

- [x] `grep -c "target: beam" .github/workflows/test.yml` = 0; `grep -c "allow_fail: true"` = 0 (the key is gone)
- [x] `grep -c snap.new .gitignore scripts/git-hooks/lib/runner-standalone.sh` → 1 and 5; the hook without a
      compiler binary → exit 1 with the build hint; a staged `x.snap.new` → exit 1
- [x] the CI command shape verified in the workflow's layout (`botopink-lang/repository/erika` + `libs`),
      from a scratch directory with `BOTOPINK_LIB_ROOTS` naming `repository/erika`:
      `botopink-lib-test --target commonJS --strict` → 3 passed, 0 failed (`erika`, `erika-linq`,
      `erika-test` and no other row); `--target erlang --strict` → 3 passed, 0 failed; the hook-stages
      step → 1 build on each target
- [x] the workflow green on GitHub — its `test` workflow green on GitHub on the remote `feat`, every row (the repaired workflow; the earlier tip was red on 4 of 5
      rows: `erlc: FileNotFound`, `GLIBC_2.36 not found`)

## Gate

- [x] every erika cell `pass` on commonJS and erlang — 6/6 (above)
- [x] `(cd repository/erika && scripts/git-hooks/pre-commit)` green: 6/6 cells (three members on both
      targets), 2/2 example builds; the workflow's command shape verified as in step 2
- [x] the workflow green on GitHub — its `test` workflow green on GitHub on the remote `feat`, every row
- [x] `repository/erika/AGENTS.md` updated; commits on `front/108-gate-erika` in the erika submodule

## What is left

| Item | Owner |
|---|---|
| `restricted-targets.txt`'s `erika-linq erlang 0` line is stale (the cell runs) | `113` (deletes the file) |
| The linux rows are `ubuntu-24.04` because nothing built from botopink-lang starts on `ubuntu-22.04` (`build.zig:745` pins glibc 2.38 → `arc4random_buf`, GLIBC_2.36; 22.04 ships 2.35) — 101's README has the row | `114` / `../../01-compiler/` (`build.zig`) |
| No windows row until the compiler's returns (gate-f) | `114` |
| `botopink-lib-test` has no workspace selector; the workflow gets "this workspace's members and nothing else" from a scratch working directory plus `BOTOPINK_LIB_ROOTS` | `113` / `115` (`modules/lib-test-runner/**`) — optional; 101 filed the same row |

## Blast radius

- `113` deletes the `erika-linq erlang 0` line with the file; `../../01-compiler/carried.md` RT-1 and
  `09-ecosystem-residuals`' "lift erika-linq targets" row close on this landing.
- No other track owns erika files this milestone. `runner-standalone.sh` is one text in the five
  library repositories; a change to it lands in all five together (the meta `hook-integrity` check 4).
