# Front 02 — cli-gate

**Priority:** critical — three CLI commands report success on failure, and the gate never compiles a `.bp` library, so every other front is verified with the libraries' eyes closed
**Depends on:** none. It **blocks nothing and widens the gate**, so it lands first
**Owns:** `modules/compiler-cli/**` · `build.zig` · `.github/workflows/**` · `scripts/**` ·
`modules/compiler-cli/tests/**` · the four `codegenEmit` early-`continue` sites (one mechanical
commit, no output change) · `comptime/tests/decorator_regression.zig`
**Does not touch:** any backend's lowering ([`../04-beam/`](../04-beam/README.md),
[`../05-erlang/`](../05-erlang/README.md), [`../06-wasm/`](../06-wasm/README.md),
[`../08-js-bridges/`](../08-js-bridges/README.md)), `libs/std/**`
([`../03-std-surface/`](../03-std-surface/README.md)), the untyped comptime path
([`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)), `utils/snap.zig` and the rest of
`codegen/tests/**` ([`../09-review-tooling/`](../09-review-tooling/README.md)).

Paths are relative to `repository/botopink-lang/`; `main.zig` and `cli/*.zig` live under
`modules/compiler-cli/src/`, everything else under `modules/compiler-core/src/`.

---

## Problem

A CLI command's exit code does not mean what it says.

```
$ botopink build            # src/broken.bp does not type-check
Compiled in 130.93ms
$ echo $?
0
$ ls out/
main.js                     # broken.js was silently dropped
$ botopink check
error: unbound variable 'noSuchFunction' at broken:2:5
$ echo $?
1
```

`botopink test` is worse: its compile guard compares two counts that measure different things, and
each `from "std"` import in the project masks one module that failed to compile — a project with one
`from "std"` module and one broken module prints `1 passed, 0 failed` and exits **0**.

And the gate never notices, because `zig build test` never compiles a `.bp` library. `zig build
test-libs` exists and is part of no gate; the sibling repos' pre-commit hooks were the only thing
that saw the library breakage this milestone opens on.

Under all of it sits an unproven assertion carried from 1.0.1-beta: the 4 decorator regression tests
pass, but two of them stay green under a mutation of the lowering they name.

## Current state

Measured against `zig-out/bin/botopink` built from HEAD, and by reading `build.zig`, the seven
repositories' workflows and their installed hooks.

| | Measured |
|---|---|
| CLI rows where exit code, output or writes contradict the contract | **14** (C1–C14), each with a reproduction |
| CLI unit tests | 53, **all** in `cli/*.zig`; `main.zig` has **zero**, so no flag parser is tested |
| build steps wired into `zig build test` | 1 of 7 (`clean-tmp`, as a prerequisite of `test`) |
| `zig build test-vscode` | points at `../../scripts/test-vscode.sh`, which **exists nowhere** |
| `zig build test-libs` at HEAD, 6 libraries × default targets | **1 passed, 7 failed, 4 skipped** — and CI's `test-libs` job sees only `libs/std`, which is red |
| `modules/compiler-cli/tests/*.sh` wired to a build step | 1 of 4 (`backend_exec.sh`); of its 2 pinned reds, 1 is stale |
| repos whose `pre-commit` gate resolves | 5 of 7; **botopink-lang, the repo that ships everything, has none** |
| sibling workflows a compiler change can trigger | **0** — no `repository_dispatch`, no `workflow_call` |
| decorator regression tests that survive a mutation of their own lowering | **2 of 4** |

`hook-integrity` is a name with no referent: no build step, workflow or script in any of the seven
repositories mentions it, and the meta repository has no `.github/` directory at all.

## Mechanism

Three clusters, each one change across several rows.

- **A module that fails to compile leaves no trace.** All four backends `continue` on `.parseError`
  and `.typeError` in `codegenEmit` (`codegen/commonJS.zig:54`, `erlang.zig:315`,
  `beam_asm.zig:414`, `wat.zig:160`), so `codegen.generate` returns fewer `ModuleOutput`s than there
  were modules and says nothing about which. `build` inspects only `comptime_err` (set solely by the
  `.validationError` arm) and exits 0; `test` compares `outputs.items.len` against a `modules.len`
  counted *before* `expandStdImports` ran. Rows C1, C2, C4.
- **Located errors die in a local.** `comptime.zig:449` propagates the lexer's error as a bare Zig
  error tag and `comptime.zig:1168-1174` returns `.parseError` with `Parser.parseError` discarded,
  so `check` can print only `error: parse error in main`. Rows C6, C7 — one change to
  `ComptimeOutput.outcome` closes both across three commands.
- **No flag parser rejects anything.** None of the four `parse*Opts` functions in `main.zig` has an
  `else` arm, so `--target=erlang` and `--frobnicate` are both silently dropped. Rows C11, C12.

The contract, the fourteen rows with their reproductions, and the fix each needs:
[`command-contract.md`](./command-contract.md). What the gate runs and what it therefore cannot
see: [`gate-coverage.md`](./gate-coverage.md). What the decorator tests prove and what they permit:
[`mutation-matrix.md`](./mutation-matrix.md).

## Steps

### Step 1 — Write the contract down

The contract table in [`command-contract.md`](./command-contract.md) — what each command reads,
writes, spawns, and what each exit code means — goes into `modules/compiler-cli/AGENTS.md`, per
command. Everything after this step is making the code match it.

Two behaviours it settles that are documented nowhere today: `build` and `test` currently **execute
the program they are compiling** (`codegen.generate` runs every emitted module through
`runtime.execute*` and stores stdout on `run_output`, which no CLI command reads), and
`build --out dist` produces a tree that neither `run` nor `clean` can see.

**Acceptance:**
- [ ] The contract table is in `modules/compiler-cli/AGENTS.md`, per command
- [ ] `codegen.generate` takes an "execute" flag; the snapshot harness sets it, the CLI does not
- [ ] No command executes the program it is compiling unless asked to

### Step 2 — A module that fails to compile must fail the command

Close C1, C2 and C4 at the source: have `codegenEmit` emit a `ModuleOutput` carrying the diagnostic
instead of `continue`, in all four backends, so `build`, `test` and any future driver share one
check. The edit is mechanical and identical in the four files and moves no emitted output; it is
listed here rather than in the backend fronts so it lands as one commit.

Then close C6 and C7 with one change to `ComptimeOutput.outcome`: a payload-carrying `parseError`
and a new `lexError`, rendered through the renderers that already exist (`lexer.zig:782`
`lexicalErrorMessage`, `lexer.zig:798` `printLexicalError`).

**Acceptance:**
- [ ] `botopink build` exits 1 and names every module that produced no artifact, and leaves no
      artifact it did not write this run
- [ ] `botopink test` compiles what compiles, runs those tests, reports the failures and exits 1 —
      and its guard compares named module sets, not counts
- [ ] A project with one `from "std"` module and one broken module reds
- [ ] All four backends carry a `.typeError` through instead of `continue`
- [ ] `botopink test` prints the located diagnostic of the module that failed, not a count
- [ ] A lex error and a parse error each render with file, line and excerpt on `build`, `check` and
      `test`

### Step 3 — The remaining contract rows

C3, C5, C8, C9, C10, C11, C12, C13, C14 — each is stated with its reproduction and its correct
behaviour in [`command-contract.md`](./command-contract.md). Two of them pair up: C11 and C12 are
one flag-parsing pass over `main.zig` (an `else` arm in each of the four `parse*Opts`, plus
`Target.fromString` validation in `parseNewOpts` and a `parsedTarget` that rejects an unknown
manifest target instead of degrading to commonJS). C5 — `check` loading `test/` as well as `src/` —
is what makes C3's message truthful, and is also what makes a CI gate on `check` able to see the
comptime-dispatch class of failure at all
([`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)).

**Acceptance:**
- [ ] Every row C1–C14 has a test that reds before the fix: a `main.zig` unit test for
      C10–C12/C14, and a script under `modules/compiler-cli/tests/` wired to step 4's build step
      for the rows that need a real project
- [ ] `botopink build`, `check` and `test` agree: on the same tree, either all three exit 0 or all
      three exit 1
- [ ] `botopink check` covers `test/` too, or its message stops naming a command that does not look
      there
- [ ] `migrate --dry-run` writes nothing, wherever the flag appears
- [ ] `format` and `format --check` count an unlexable or unparseable file as an error
- [ ] An unrecognised flag or an unsupported target reds instead of being dropped

### Step 4 — The gate must cover what ships

Build the local gate and the CI workflow described in
[`gate-coverage.md`](./gate-coverage.md#what-the-gate-should-be): six ordered local steps ending in
`test-libs` and `test-backends`, installed as botopink-lang's own `pre-commit`, and one CI workflow
with the sibling repos checked out. `zig build test-cli` is new and wires all four
`modules/compiler-cli/tests/*.sh`, each honouring `BOTOPINK_SKIP_BUILD`.

The libraries cost seconds (3.1 s for 6 libraries × 2 targets, measured); the expensive piece is the
cold runtime cache — 532 re-executions, which is the price of the rule that the merge-deciding run
is cold.

**Acceptance:**
- [ ] The gate documented in `AGENTS.md` (and used by every front) is
      `zig build test && zig build test-libs`
- [ ] `zig build test-cli` exists and runs all four `modules/compiler-cli/tests/*.sh`; each is green
      or deleted, and each honours `BOTOPINK_SKIP_BUILD`
- [ ] `test_tooling.sh` asserts the output the runner actually emits (`TEST …` per test,
      `4 passed, 0 failed`), not a `running N tests` banner that no version prints
- [ ] The two `pin_*_red` helpers in `backend_exec.sh` are gone: each cell is a hard assert or the
      cell is deleted
- [ ] `zig build test-vscode` points at a script that exists, or the step is deleted
- [ ] `test-libs` covers `libs/std` and every sibling library the checkout can see, per target, and
      names what it skipped and why
- [ ] CI checks out the sibling repos and runs `test-libs` over them; a library failure fails the
      job **by name**, with the failing module's diagnostic in the log
- [ ] botopink-lang has an installed `pre-commit` that runs the local gate, and the meta repo's
      dangling hook symlink is replaced
- [ ] A module not reached by a `mod` path fails, or is counted and reported — today
      `cli/sources.zig:65-67` warns and 1147 lines of `libs/std` go uncompiled

### Step 5 — Run the mutation matrix

Ten mutations over the 4 decorator regression tests, each applied in a dirty tree, verified with
`zig build test -Dtest-filter="decorator regression"`, then reverted. The matrix with its predicted
verdicts is [`mutation-matrix.md`](./mutation-matrix.md#the-matrix). M1, M2, M4 and M10 are
predicted to pass — that is the finding, not a failure of the run.

**Acceptance:**
- [ ] Every row of the matrix has a recorded verdict, run on a cold runtime cache
- [ ] Each disagreement with the "expected" column is written into this front's notes

### Step 6 — Tighten the blind tests, and reach the fold fusion

Three of the four tests need a companion the mutation cannot satisfy; the rule and the per-test
additions are in [`mutation-matrix.md`](./mutation-matrix.md#how-to-tighten-the-blind-ones). The
`@emit` test can assert the contributed source text without a new compiler hook, through
`OkData.comptime_traces` (`comptime.zig:108`, `comptime/trace.zig:13`). Then add the test no
decorator test reaches today: a body that folds an accumulator through `lists:foldl/3`.

**Acceptance:**
- [ ] Each of the 4 tests fails under every mutation in step 5's matrix that targets its lowering,
      M1/M2/M4/M10 included
- [ ] `assertRejects` compares the full message, and each call site names the lowering it guards in
      a comment
- [ ] The `@emit` test asserts the contributed source text, not only that the module compiles
- [ ] A decorator test exercises `lists:foldl/3` and reds when `foldFusionExpr` is made to discard
      the accumulator, living next to the others in `comptime/tests/decorator_regression.zig`
- [ ] `zig build test` stays green from a cold runtime cache (0 failures, 0 leaks, no
      `.snap.md.new`)

## Gate

- [ ] `zig build test` from a **cold** runtime cache, green, in this front's worktree
- [ ] `zig build test-cli` green — the step this front creates, running all four scripts
- [ ] `zig build test-libs` runs and reports; every red cell is either a library another front owns
      (named, with its front) or a hard failure
- [ ] Snapshots byte-identical: nothing in this front changes emitted output, including the
      `codegenEmit` commit
- [ ] `modules/compiler-cli/AGENTS.md` carries the contract; `AGENTS.md` of every other directory
      touched, updated in the same commit
- [ ] Commit on `fix/cli-gate`; no push, no merge — landing is the maintainer's step

## Blast radius

- **Nothing that ships changes shape.** No lowering moves, no snapshot is re-recorded. The
  `codegenEmit` change touches four backend files but only replaces a `continue` with a
  diagnostic-carrying `ModuleOutput`; the backend fronts can be told their output is untouched.
- **The gate goes red on landing, by design.** Widening it surfaces what was never looked at:
  `libs/std` ([`../03-std-surface/`](../03-std-surface/README.md)), erika and jhonstart's residual
  `unbound_var` after [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md), rakun's
  missing `server` dependency (the library-repos front), wasm's 0/278 empty RUN LOGs
  ([`../06-wasm/`](../06-wasm/README.md)). This front lands the machinery and a named, counted skip
  per known-red library; each flips to a hard assert as its owning front lands.
- **Commit latency.** Installing botopink-lang's `pre-commit` makes every commit in that repo pay
  the local gate. Steps 1–4 are seconds; the cold-cache rule applies only to the run that decides a
  merge.
- **CI minutes.** One extra job checking out five sibling repositories, plus `test-backends`.
  Measured cost of the library sweep itself: 3.1 s.

## Notes

- **This front changes the gate itself**, so it lands before the fronts whose gate it widens. It
  conflicts with nothing in the milestone's matrix: it owns the CLI, the build files and the
  workflows, and no other front touches them.
- **`comptime/tests/decorator_regression.zig` is normally the review-tooling front's file**
  (`comptime/tests/**`). Steps 5 and 6 are the only rows in this milestone that touch it; either
  this front holds it and the review-tooling front starts after, or steps 5–6 move there with this
  analysis. They cannot run at the same time.
- **The four `codegenEmit` sites are the backend fronts' files.** The change is mechanical and
  output-neutral, so it is cheaper as one commit here than as four coordinated edits; whoever runs
  this front must say so when the backend fronts open.
- The `executeWat` decision — whether wasm is ever executed, and what the 278 empty RUN LOGs mean —
  is [`../06-wasm/`](../06-wasm/README.md)'s. This front only stops the gate claiming coverage it
  does not have.
- `.botopinkbuild/tmp/decorator/decorator_<hash>.erl` surviving a `botopink check` is the fastest
  way to see what a decorator body lowered to; the same text is what `trace.Entry.erl` carries.
