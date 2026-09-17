# Front 09 — hygiene

**Status:** step 1 (group E, the frame protocol) **delivered** by 1.0.2-beta front 11 — see
[Step 1](#step-1--close-the-frame-protocol-hole-group-e-510--delivered). Steps 2–6 carried; each sweep runs
after the front that owns the file it sweeps.

**Priority:** low, except [5.16](./build-files.md) — the remaining items are cosmetic apart from one
silently-wrong build
**Depends on:** per step — group A waits on [`../03-wasm/`](../03-wasm/README.md)'s `executeWat`
decision (its H3); group B's root `build.zig` and CI edits wait on
[`../05-cli-residuals/`](../05-cli-residuals/README.md), which owns both; group C's and group D's
comment sweeps wait on the fronts that own the swept files (01–08); 5.13's fixture waits on
[`../07-comptime-dedup/`](../07-comptime-dedup/README.md); the decisions (step 6) wait on nobody but
the maintainer
**Owns:** `comptime/runtime/persistent_erl.zig` (the residual below) · `meta:build.zig`, root
`test_pub.zig`, `test_format.zig`, `modules/*/build.zig` + `.zon` (group B) · `libs/std/botopink.json`,
`libs/std/AGENTS.md` and comments in `libs/std/**` (group C) · `examples/**`, `README.md`, `docs.md`,
every `AGENTS.md`, and comments
**Does not touch:** any behaviour. Every edit outside groups E and B is a comment, a manifest, a
doc or a dead file — see [Ownership conflicts](#ownership-conflicts), because three of the five
groups sweep comments through files the backend fronts own

---

## Problem

Fourteen items the 1.0.1-beta milestone did not reach: orphan std files, broken
scripts/manifests/hooks, dead build files, retired vocabulary in comments, the stdout/protocol
collision in the comptime runtime, the license. Item numbers are kept from
[`../../1.0.1-beta/05-repo-hygiene.md`](../../1.0.1-beta/05-repo-hygiene.md) (5.11, 5.12, 5.15 and
the parser half of 5.13 closed there) so existing cross-references still resolve.

Two of the fourteen are not hygiene and should not be scheduled as such:

| Item | Why it is not cosmetic |
|---|---|
| **5.10** | A comptime body that writes to stdout corrupts the `persistent_erl` frame protocol, and `readFrame` then allocates whatever the corrupted length prefix says — up to 4 GiB — with no bound. `meta:erl_crash.dump` is the artefact of exactly this |
| **5.16** | `modules/compiler-core/build.zig` builds a compiler with **5 of 23** std modules and succeeds. `modules/compiler-core/AGENTS.md:28-31` tells the reader to use it |

Everything else is comments, dead files and one missing license decision.

## Current state

Every row was re-derived at the 1.0.2-beta commit this spec was written against; the 1.0.2-beta
cli-gate and std-surface fronts have landed since and close part of groups B, C and the hook half of
5.5 — **re-derive each row before acting on it**. Paths are relative to `repository/botopink-lang/`
unless they start with `meta:`.

Two facts decide the shape of two whole groups, and both contradict what the tree says about itself:

- **`wasm3` and `wat_runtime` are gone.** No file named `wasm3*`, `wat_runtime*` or `wat_to_wasm*`
  exists, there is no `vendor/`, and nothing in the tree calls `linkLibC`, `link_libc` or
  `@cImport`. What is left is dead code, comments asserting the removed architecture in the present
  tense, and a CI step that downloads a binary nothing invokes.
- **Hooks are installed on this machine only, and not by anything in the repos.** erika, jhonstart,
  onze, rakun and vscode-extension have a working `pre-commit` symlink under
  `meta:.git/modules/repository/<repo>/hooks/`; `botopink-lang` (its own `.git/`) holds only
  `*.sample`; emilia has none; `meta:.git/hooks/pre-commit` is a dangling symlink. A fresh clone
  gets **no** hook anywhere, and the `scripts/install-hooks.sh` five `AGENTS.md`s tell you to run
  exists in no repository — see [`decisions.md`](./decisions.md). *Since then:* 1.0.2-beta cli-gate
  shipped `scripts/install-hooks.sh` and `scripts/gate.sh` in botopink-lang; installing the hook
  and the meta repo's dangling link are [`../05-cli-residuals/`](../05-cli-residuals/README.md)
  step 6.

## Groups

The fourteen items are five branches plus two decisions. Items inside a group share files and must
land together; the groups are file-disjoint from each other.

| Group | Items | What it is | Order |
|---|---|---|---|
| E — the comptime frame protocol | 5.10 | The frame-protocol guard | **delivered** |
| [A — the removed WAT runtime](./wat-runtime.md) | 5.6, 5.7 | Every trace of the removed wasm3/`wat_runtime` runtime, in source, comments and CI | 2nd — 5.7 is unactionable until 5.6's decision is made |
| [B — build files that lie](./build-files.md) | 5.4, 5.16, 5.17 | Build files and root scripts that do not work, or work wrongly | 3rd |
| [C — `libs/std` declarations and one stale filename](./std-declarations.md) | 5.1, 5.2, 5.3, 5.14 | `libs/std`'s declared surface (its code half landed with 1.0.2-beta std-surface), and the 33 comments still naming `primitives.d.bp` | sweep after 01–04 |
| [D — instructions and vocabulary that do not work](./vocabulary.md) | 5.8, 5.13, + 1.0.3-beta review row 9 | An example header, `docs.md`'s `implement` example, and ~24 comments teaching forms the compiler rejects | sweep after 01–07 |
| [Decisions — not work](./decisions.md) | 5.9, 5.5 | License; whether the meta repo needs a gate at all | before their groups can close |

## Steps

Each group is a step; the deep dive holds the deciding sites and the smallest fix per item.

### Step 1 — Close the frame-protocol hole (group E, 5.10) — delivered

Landed with 1.0.2-beta: the default logger handler is off `standard_io`, `Mod:main()` runs under its
own group leader, a frame is capped at 16 MiB (a larger length is a transport error with a message),
and `erl.stderr.log` is a write-only debug log (truncated per spawn, never read back — written in
`comptime/runtime/AGENTS.md`). A race fix came with it: the server is built in a hashed directory
and renamed into place. `meta:erl_crash.dump` is deleted.

**Residual (cosmetic):** `erl.stderr.log` is still one path shared by every process that spawns the
server, so parallel test runs interleave it. Give it a per-spawn name, or say in
`comptime/runtime/AGENTS.md` that it is best-effort. And the callers (`template_eval.zig`,
`decorator_eval.zig`) still map every transport error to `EvalFailed`, so `lastTransportError()`
never reaches a diagnostic — no front owns those two files now; take it here if it stays a one-line
change.

**Acceptance:**
- [ ] `erl.stderr.log` is per spawn, or documented as shared and best-effort

### Step 2 — Erase the removed WAT runtime (group A, 5.6 · 5.7)

**Settle first:** whether a WAT runtime is wired back in. `executeWat`
(`codegen/runtime.zig:547-558`) returns `""` unconditionally and is honestly documented as a stub —
it is the only accurate wasm3-adjacent comment in the tree. Everything in this group reads
differently depending on that answer, so do not start until
[`../03-wasm/`](../03-wasm/README.md) has made it (its step 3, handed over as its H3). Then delete the dead code, rewrite the comments
that assert the removed architecture in the present tense, and fix the four CI claims.
[`wat-runtime.md`](./wat-runtime.md).

**Acceptance:**
- [ ] No `wasm3` / `wat_runtime` / `wat_to_wasm` / `wasm3_host` mention left in the tree
- [ ] `build_options` and `emitFnWat` deleted, or each has a named user
- [ ] `libcResolvedTarget` deleted, or its comment explains a reason that still exists
- [ ] Every comment about the comptime runtime names the persistent `erl` server
- [ ] `zig build` and `zig build test` green on Linux-gnu and on the CI runners

### Step 3 — Delete the build files that do not work (group B, 5.4 · 5.16 · 5.17)

A `zig build test-vscode` step whose script does not exist, a `meta:build.zig` whose every path
dangles while declaring the same step names as the real build, a second hardcoded list of std
modules that silently builds a compiler missing 18 of them, and two unreachable root `.zig` files
that `AGENTS.md` presents as first-class. [`build-files.md`](./build-files.md).
Re-derive 5.4 first: 1.0.2-beta cli-gate's step 4 required `test-vscode` to point at a script that
exists or be deleted. Root `build.zig` and `.github/workflows/**` are
[`../05-cli-residuals/`](../05-cli-residuals/README.md)'s — land after it or hand it the edit.

**Acceptance:**
- [ ] `zig build test-vscode` runs and passes, or the step and every reference to it are gone
- [ ] `zig build` from any directory either works or fails with "no build.zig"
- [ ] No second list of std modules exists anywhere
- [ ] No unreachable `.zig` file sits at a repo root, and `AGENTS.md` trees match the disk

### Step 4 — Make `libs/std`'s declared surface and its names true (group C, 5.1 · 5.2 · 5.3 · 5.14)

The code half landed with 1.0.2-beta std-surface (`reflect.bp`/`types.bp` deleted, the tests
moved, the manifest fixed). This group owns what is left: re-deriving 5.1–5.3 against that, and the
33 comments still naming `primitives.d.bp` — swept after the fronts that own those files.
[`std-declarations.md`](./std-declarations.md).

**Acceptance:**
- [ ] `grep -rn 'primitives\.d\.bp'` returns only the two extension-assertion tests
- [ ] Every `files` entry in every `botopink.json` in the workspace resolves
- [ ] `libs/std/AGENTS.md`'s tree matches `src/`

### Step 5 — Stop teaching forms the compiler rejects (group D, 5.8 · 5.13 · docs)

`examples/hello.bp`'s header gives two commands that cannot work, and ~24 comments plus one fixture
present `@external(<target>, …)` — a form `ast.zig:1796` can never match — as current.
[`vocabulary.md`](./vocabulary.md). And `docs.md` shows `implement A for B { … }` without `val`,
which does not parse (1.0.3-beta review row 9, measured at `botopink-lang` `41981e3`). Fix it in the
1.0.2 surface — [`../14-tooling-and-docs/`](../14-tooling-and-docs/README.md) rewrites `docs.md` for
1.0.3 later and only checks that this closed.

**Acceptance:**
- [ ] No comment, fixture or `.bp` file presents `@external(<target>, …)` or `@[external(…)]` as
      current
- [ ] `examples/hello.bp`'s header works when pasted into a shell
- [ ] Whether a lowercase `@external` is rejected or accepted is decided and written down
- [ ] Every code fence in `docs.md` that claims to be botopink passes `botopink check`

### Step 6 — Get the two answers (5.9 · 5.5)

The license, and whether the meta repo needs a gate at all plus how a hook gets installed. These do
not have a smallest fix; they have an answer someone has to give, and nothing in their groups closes
until they do. [`decisions.md`](./decisions.md).

**Acceptance:**
- [ ] `LICENSE` in all seven repos; `"license"` in `vscode-extension/package.json`
- [ ] `git config core.hooksPath scripts/git-hooks` (or the chosen equivalent) documented in every
      repo's `AGENTS.md`, and the hook demonstrably runs after following it
- [ ] `meta:.git/hooks/pre-commit` either resolves or is gone
- [ ] No script or `AGENTS.md` references `meta:scripts/` or `botopink/projects`

## Gate

- [ ] `zig build`, `zig build test` from a **cold** runtime cache, and `zig build test-libs`, green
      in this front's worktree (group C may add known failures — register them by name in the front
      that owns them, do not fix them here)
- [ ] Every item fixed, or closed with a written reason in this front's files
- [ ] Matching `AGENTS.md` files updated in the same commits
- [ ] Commit on `fix/hygiene`; no push, no merge

## Blast radius

Nothing in this front changes emitted output, so no snapshot moves — with two exceptions to plan
for:

- **5.13's fixture rewrite** (`comptime/tests/infer_decls.zig:518`) re-records one comptime
  snapshot, in a directory [`../06-checker/`](../06-checker/README.md) and
  [`../07-comptime-dedup/`](../07-comptime-dedup/README.md) both move. Land it after both, or hand
  that single row to whichever is in flight.
- **Group B's deletions change what builds**: dropping `modules/*/build.zig` removes an entry point
  `modules/compiler-core/AGENTS.md:15-16` currently documents, and dropping `libcResolvedTarget`
  (group A) changes the target triple every `zig build` uses on Linux.

## Ownership conflicts

This front's behaviour edits own their files; its comment sweeps do not — and the sweeps are most of
the work:

| Where | What it touches | Whose file |
|---|---|---|
| 5.14 (33 sites), 5.13 (~24 sites) | comments in `codegen/erlang.zig`, `codegen/commonJS.zig`, `codegen/beam_asm.zig`, `comptime/infer.zig`, `comptime/env.zig`, `codegen/tests/**` | [`../01-beam/`](../01-beam/README.md), [`../02-erlang/`](../02-erlang/README.md), [`../04-js-bridges/`](../04-js-bridges/README.md), [`../06-checker/`](../06-checker/README.md), [`../08-review-backlog/`](../08-review-backlog/README.md) |
| 5.4, 5.16, A1 | root `build.zig` (the `test-vscode` step, `build_options`, `libcResolvedTarget`) and `.github/workflows/test.yml` | [`../05-cli-residuals/`](../05-cli-residuals/README.md) owns both |
| A1 | `codegen/wat.zig:130` `emitFnWat`, `libs/std/src/builtins.d.bp:269-279` | [`../03-wasm/`](../03-wasm/README.md); `libs/std` has no owner this milestone, so this front takes the `builtins.d.bp` line |
| E | `comptime/runtime/persistent_erl.zig` | this front (claimed in 1.0.2-beta; the residual only) |

The practical rule: a comment-only edit in another front's file is safe to *make* and expensive to
*merge*. Do each sweep in one commit per owning file, last, after the fronts that own those files
have landed — or hand the sweep to them.

## Notes

- `codegen/wat.zig:2416-2419` is a self-documented known gap in the same family as group A
  (`$__emit`, `$__compilerError`, `$__binding_ref` "are defined by the `wat_runtime` prelude … In
  the whole-program path nothing defines them"). It belongs to the WAT-execution decision, not
  here — cross-reference it rather than editing it.
- The `modules/compiler-core/build.zig` header is unmodified `zig init` boilerplate with a global
  `fu`→`f` corruption (`fnction` at `:3, 5, 111, 121`) — a reason to delete rather than repair.
- 5.5's answer is a precondition for
  [`../10-library-repos/emilia.md`](../10-library-repos/emilia.md): giving emilia the hook source
  its siblings have does not give it a gate, because no sibling's hook is installed either. It is
  also what [`../05-cli-residuals/`](../05-cli-residuals/README.md) step 6 (f) applies to the meta
  repo's dangling link — answer it early; it blocks two fronts and costs no code.
