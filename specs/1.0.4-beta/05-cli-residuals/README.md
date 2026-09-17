# Front 05 — cli-residuals

**Status:** **delivered** 2026-09-17 (`botopink-lang` merge `440a1d3`). Handoffs: the language-server half of step 5 — `project_graph.zig` still swallows
a missing dependency (`:171`) and an unreadable file (`:210`) with `catch continue` — is an unowned
item; `codegen.generate` drops failed-module entries because `tests/helpers.zig` renders its own
diagnostic — reading `result.diagnostic` there is [`../08-review-backlog/`](../08-review-backlog/README.md)'s.
The lib-test-runner's unit tests now run under the root `zig build test` (its own `build.zig` +
`.zon` can go — [`../09-hygiene/`](../09-hygiene/README.md)). The hook is self-contained (5.5b) and
`gate.sh` clears `GIT_DIR`/`GIT_INDEX_FILE` after the staged stage: without it the bpmp install tests
ran `git` against the real repository from inside the hook.
**Priority:** medium — the gate the 1.0.2-beta cli-gate front built is in use and catches a broken
library; what is left is a driver that still runs the program it compiles, diagnostics that still
die before the CLI can print them, three decorator tests that stay green under a mutation of their
own lowering, and gate pieces that exist but are not installed or not wired
**Depends on:** nothing — the four backend fronts step 2 waited on landed 2026-09-17 (`ed15323`).
Step 2 edits one site in each backend file, which
[`../01-backend-residuals/`](../01-backend-residuals/README.md) now owns: sequence it against that
front ([`../fronts.md`](../fronts.md#conflict-matrix) note 1)
**Owns:** `modules/compiler-cli/**` · `modules/lib-test-runner/**` · `build.zig` · `.github/workflows/**`
· `scripts/**` **except** `scripts/snap_audit.sh` · `src/codegen.zig` (the `generate` driver) ·
`src/codegen/snapshot.zig` (only the call that sets the execute flag) · `src/comptime.zig`
(`ComptimeOutput.outcome`) · the four `codegenEmit` early-`continue` sites (step 2, one mechanical
commit) · `src/comptime/tests/decorator_regression.zig` (carved out of
[`../08-review-backlog/`](../08-review-backlog/README.md)'s `comptime/tests/**`) · no snapshot
directory
**Does not touch:** any backend's lowering or `src/codegen/runtime.zig`
([`../01-backend-residuals/`](../01-backend-residuals/README.md)) · `src/comptime/infer.zig` and
`src/parser/{decls,exprs,patterns}.zig` ([`../06-checker/`](../06-checker/README.md)) ·
`utils/snap.zig` and the rest of the test sources ([`../08-review-backlog/`](../08-review-backlog/README.md))
· `libs/std/**` · `modules/language-server/**` (see step 5)

Paths are relative to `repository/botopink-lang/`; `main.zig` and `cli/*.zig` live under
`modules/compiler-cli/src/`, `src/` means `modules/compiler-core/src/`. Line numbers in the carried
deep dives were measured at the 1.0.2-beta commit — re-locate by symbol before editing.

---

## Delivered by 1.0.2-beta cli-gate

Not to redo: `build`, `check` and `test` fail on a module that does not compile; the command
contract (rows C1–C14 of [`command-contract.md`](./command-contract.md)) is written into
`modules/compiler-cli/AGENTS.md` and each row has a test; `zig build test-cli` runs every
`modules/compiler-cli/tests/*.sh`; `scripts/gate.sh [--cold] [--staged]` is the local gate;
`scripts/install-hooks.sh` installs it; `zig build test-libs` covers `libs/std` and every checked-out
sibling, with the known reds named in `scripts/known-red-libs.txt`; CI runs a libs job; the mutation
matrix of [`mutation-matrix.md`](./mutation-matrix.md) was run.

## Problem

Nine things the cli-gate front did not reach, grouped by the file they need, and one the beam
front handed over.

| # | Residual | Where |
|---|---|---|
| a | `build` and `test` still **execute** every module they emit: `codegen.generate` runs `runtime.execute*` per module and stores stdout on a `run_output` no CLI command reads, so a program's side effects happen at build time | `src/codegen.zig` |
| b | The four backends still `continue` on `.parseError`/`.typeError` in `codegenEmit`; the CLI's check lives in the driver, so any other caller of `generate` still loses the module silently | `codegen/{commonJS,erlang,beam_asm,wat}.zig` |
| c | A lex or parse error carries **no location** in `ComptimeOutput.outcome` — `check` prints `parse error in main` (1.0.3-beta review row 8) | `src/comptime.zig` |
| d | Step 6 of cli-gate — tighten the three blind decorator tests and add the fold-fusion test — was not done | `src/comptime/tests/decorator_regression.zig` |
| e | `scripts/install-hooks.sh` exists but the pre-commit hook is **not installed** in botopink-lang; installing it before the live worktrees rebase onto a base at or after the backend landings (`ed15323`) would red their commits on a gate they were not cut against | local state |
| f | The meta repository's `.git/hooks/pre-commit` is still a **dangling** symlink | meta repo |
| g | `zig build test-bpmp` (108 tests) is in no gate | `scripts/gate.sh`, `.github/workflows/**` |
| h | `modules/lib-test-runner` has no owner, and a library with **no tests** is never compiled by `test-libs` | `modules/lib-test-runner/**` |
| i | `print((1);` fails with **no recorded location** — the parser returns an error without filling `Parser.parseError` | `src/parser.zig` or `src/parser/exprs.zig` |
| j | `scripts/beam_export_audit.sh` (landed with 1.0.4-beta beam, 290/290) is in **no gate**: nothing stops a narrow `{exports, …}` form hiding a beam loader rejection again | `scripts/gate.sh`, `.github/workflows/**` |

## Steps

### Step 1 — `generate` does not execute unless asked (a)

Give `codegen.generate` an execute flag. The snapshot harness sets it; `build`, `test`, `run` and the
language server do not. The facts and the measured cost are in
[`command-contract.md` § two contract facts](./command-contract.md#two-contract-facts-that-hold-at-head-and-are-documented-nowhere).

**Acceptance:**
- [x] `codegen.generate` takes the flag; `rg 'generate\(' modules/` shows every caller passing it
- [x] `botopink build` of a program whose body prints leaves no runtime-cache entry and spawns no
      `node`/`erl`
- [x] Snapshots byte-identical, same pass count

### Step 2 — the diagnostic travels in `ModuleOutput` (b)

Replace the `continue` in each backend's `codegenEmit` with a `ModuleOutput` carrying the
diagnostic, and have the driver check read it instead of comparing module sets. One commit, four
sites, no output change — [`command-contract.md` § the diagnostic exists and is discarded three times](./command-contract.md#the-diagnostic-exists-and-is-discarded-three-times).

**Acceptance:**
- [x] No `codegenEmit` `continue`s on `.parseError` or `.typeError`
- [x] `build`, `check`, `test` still agree on the C1–C14 tests, now through one check
- [x] Snapshots byte-identical

### Step 3 — located lex and parse errors (c, i)

A payload-carrying `.parseError` and a new `.lexError` on `ComptimeOutput.outcome`, rendered by the
renderers that exist (`lexicalErrorMessage`, `printLexicalError` in `lexer.zig`; the parse-error
printer `format` already uses). Then make `print((1);` fill `Parser.parseError`. If that fix lands in
`src/parser/exprs.zig`, it is [`../06-checker/`](../06-checker/README.md)'s file: stop and hand the
reproduction over, keeping the acceptance here.

**Acceptance:**
- [x] An unterminated string and an unbalanced paren each render with file, line and excerpt on
      `build`, `check` and `test` — not `parse error in main`, not a bare `UnterminatedString`
- [x] `print((1);` reports a location
- [x] A CLI test per case under `modules/compiler-cli/tests/`

### Step 4 — the decorator tests prove their lowering (d)

The per-test companions and the fold-fusion test are in
[`mutation-matrix.md` § how to tighten the blind ones](./mutation-matrix.md#how-to-tighten-the-blind-ones).
Record the matrix verdicts the cli-gate run produced in this front's notes before changing a test,
so the tightening is checked against measured, not predicted, blindness.

**Acceptance:**
- [x] Each of the 4 tests fails under every mutation in the matrix that targets its lowering,
      M1/M2/M4/M10 included
- [x] `assertRejects` compares the full message; each call site names the lowering it guards
- [x] The `@emit` test asserts the contributed source text through `OkData.comptime_traces`
- [x] A decorator test exercises `lists:foldl/3` and reds when `foldFusionExpr` discards the
      accumulator

### Step 5 — the CLI half of what other fronts found

- `cli/libs.zig` (the `files` check, ~`:302`): a `botopink.json` `files` entry that does not exist
  produces a located diagnostic naming the path, not a bare error name (1.0.2-beta std-surface
  residual).
- Re-derive, and close if still open: the `cli/libs.zig` test that synthesises a `libs/server` that
  exists nowhere (~`:669`), and `language-server/src/project_graph.zig` (~`:171`) swallowing a
  missing dependency — both handed over by 1.0.2-beta library-repos. The language server has no
  owner this milestone; if the LSP half is still open, register it in
  [`../fronts.md`](../fronts.md#unowned-items) rather than editing it.

**Acceptance:**
- [x] A missing `files` entry reports the path it looked for, with the manifest's location
- [x] No compiler test synthesises a library that does not exist
- [ ] A missing dependency is reported the same way by the CLI and the language server, or the LSP
      half is registered as unowned

### Step 6 — the gate is installed and covers what ships (e, f, g, h, j)

- **(g)** `scripts/gate.sh` runs `zig build test-bpmp`; the CI workflow runs it.
- **(j)** `scripts/gate.sh` and CI run `scripts/beam_export_audit.sh`; a rejected module names the
  function and the reason.
- **(h)** Take `modules/lib-test-runner` (it is the engine of `test-libs`): a library with no test
  block is still **compiled** per target and reported, so a library that never wrote a test cannot
  be broken silently.
- **(e)** Run `scripts/install-hooks.sh` in botopink-lang once every live worktree is on a base at or
  after `ed15323` (the backend landings); say so in `AGENTS.md`'s gate section.
- **(f)** Replace or delete `meta:.git/hooks/pre-commit` according to
  [`../09-hygiene/decisions.md`](../09-hygiene/decisions.md) item 5.5 (whether the meta repo has a
  gate). If 5.5 is unanswered when the rest of this step is done, delete the dangling link and
  record that the decision is still open.

**Acceptance:**
- [x] `scripts/gate.sh` and CI run `test-bpmp` and `scripts/beam_export_audit.sh` (290/290 at `ed15323`)
- [x] A scratch library with source and no `test` block that does not compile reds `test-libs`
- [x] botopink-lang's `.git/hooks/pre-commit` resolves and runs `scripts/gate.sh --staged`
- [x] `meta:.git/hooks/pre-commit` resolves or is gone (deleted — decision 5.5a: no meta gate)

## Gate

- [x] `scripts/gate.sh --cold` green in this front's worktree (zig build, cold `zig build test`,
      `test-cli`, `test-libs`, and `test-bpmp` once step 6 lands)
- [x] Snapshots byte-identical across steps 1, 2 and 6; step 3 re-records only a snapshot that pins
      an unlocated parse/lex message, each read
- [x] `modules/compiler-cli/AGENTS.md` and the `AGENTS.md` of every other directory touched, updated
      in the same commit
- [ ] Commit on `fix/cli-residuals`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Nothing that ships changes shape**, except that `build` stops spawning the program (step 1) —
  faster, and side effects no longer happen at build time.
- **Step 2 touches the four backend files** after their fronts land; it is output-neutral, and the
  backend owners are told so in the landing note.
- **Step 3 changes what a parse or lex failure prints** everywhere it is shown: CLI, error
  snapshots that pin the unlocated text, and the library gate's log.
- **Step 6 (e) makes every botopink-lang commit pay `scripts/gate.sh --staged`.**
- **Step 6 (h) may red a library** that has no tests and does not compile; it is registered in
  `scripts/known-red-libs.txt` with its owner, not fixed here.

## Notes

- `scripts/beam_export_audit.sh` was written by the 1.0.4-beta beam front; wiring it into
  `scripts/gate.sh` and CI is this front's step 6 (j).
- `executeWat` now executes (1.0.4-beta wasm, `wasmtime run`); step 1 only separates "emit" from
  "execute" in the driver, and the snapshot harness keeps executing wasm like the other three.
- `comptime/error.zig` rendering `┌─ :L:C` with no file name is the checker's file and is listed
  there ([`../06-checker/README.md`](../06-checker/README.md)); step 3 must not render a second,
  different location format for parse errors — use the one the checker's fix produces, or agree it
  first.
