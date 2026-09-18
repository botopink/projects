# Front 09 — hygiene

**Delivered** — all six steps landed, in five waves: step 1 (the comptime frame protocol) by
1.0.2-beta front 11 with its residual documented in `e98a5da`; step 3 by `e98a5da` + `8887865`
(dead module build files, the root test stubs, `meta:build.zig`, and `modules/lib-test-runner`'s
standalone `build.zig` + `.zon`); step 6 by decisions 5.5a, 5.5b and 5.9 (MIT in the seven code
repos, `botopink-lang` `af9b5b6`); and the three comment sweeps — step 2 `2997a5b`, step 4 `02709dd`,
step 5 `594e262`.

What is left is not a step: it is the **tail of each sweep in the files another front still owned**,
and it is named below with a measured count.

**Owned:** `comptime/runtime/persistent_erl.zig` · `modules/lib-test-runner/build.zig` + `.zon`, the
root `build.zig`'s `test-vscode` step and its CI reference (5.4) · `libs/std/botopink.json`,
`libs/std/AGENTS.md` and comments in `libs/std/**` · `examples/**`, `README.md`, `docs.md`, every
`AGENTS.md`, and comments.

**Touched no behaviour.** Every edit outside groups E and B is a comment, a manifest, a doc or a dead
file — see [Ownership conflicts](#ownership-conflicts), because three of the five groups sweep
comments through files the backend fronts own.

---

## Problem

Fourteen items the 1.0.1-beta milestone did not reach: orphan std files, broken
scripts/manifests/hooks, dead build files, retired vocabulary in comments, the stdout/protocol
collision in the comptime runtime, the license. Item numbers are kept from
[`../../1.0.1-beta/05-repo-hygiene.md`](../../1.0.1-beta/05-repo-hygiene.md) (5.11, 5.12, 5.15 and
the parser half of 5.13 closed there) so existing cross-references still resolve.

Two of the fourteen were not hygiene and were not scheduled as such:

| Item | Why it is not cosmetic |
|---|---|
| **5.10** | A comptime body that writes to stdout corrupts the `persistent_erl` frame protocol, and `readFrame` then allocates whatever the corrupted length prefix says — up to 4 GiB — with no bound. `meta:erl_crash.dump` was the artefact of exactly this |
| **5.16** | `modules/compiler-core/build.zig` built a compiler with **5 of 23** std modules and succeeded. `modules/compiler-core/AGENTS.md:28-31` told the reader to use it |

Everything else was comments, dead files and one missing license decision.

## Two facts that decided two whole groups

Both contradicted what the tree said about itself.

- **`wasm3` and `wat_runtime` are gone.** No file named `wasm3*`, `wat_runtime*` or `wat_to_wasm*`
  exists, there is no `vendor/`, and nothing in the tree calls `linkLibC`, `link_libc` or
  `@cImport`. What was left was dead code and comments asserting the removed architecture in the
  present tense. 1.0.4-beta wasm then made `executeWat` run `wasmtime run`, so the CI's wasmtime
  install has a real user to describe.
- **Hooks were installed on this machine only, and not by anything in the repos.** A fresh clone got
  **no** hook anywhere, and the `scripts/install-hooks.sh` five `AGENTS.md`s told you to run existed
  in no repository. Decision 5.5b settled it: `git config core.hooksPath scripts/git-hooks` per repo,
  documented in each `AGENTS.md`; the meta repository has no gate (5.5a) and its dangling
  `.git/hooks/pre-commit` link is deleted.

## Groups, and what closed each

| Group | Items | What it was | Closed by |
|---|---|---|---|
| E — the comptime frame protocol | 5.10 | The frame-protocol guard: the default logger off `standard_io`, `Mod:main()` under its own group leader, a 16 MiB frame cap (a larger length is a transport error with a message), `erl.stderr.log` as a write-only debug log, the server built in a hashed directory and renamed into place. `meta:erl_crash.dump` deleted | 1.0.2-beta front 11; residual documented `e98a5da` |
| [A — the removed WAT runtime](./wat-runtime.md) | 5.6, 5.7 | Every trace of the removed wasm3/`wat_runtime` runtime, in source, comments and CI | `2997a5b` |
| [B — build files that lie](./build-files.md) | 5.4, 5.16, 5.17 | Build files and root scripts that did not work, or worked wrongly | `e98a5da` (5.16a, 5.16b, 5.17; `meta:build.zig` deleted), `8887865` (lib-test-runner's pair — its unit tests run under the root `zig build test`); 5.4 verified — `zig build test-vscode` runs `scripts/test-vscode.sh`, which exists |
| [C — `libs/std` declarations and one stale filename](./std-declarations.md) | 5.1, 5.2, 5.3, 5.14 | `libs/std`'s declared surface (its code half landed with 1.0.2-beta std-surface), and the comments still naming `primitives.d.bp` | `02709dd` — the `libs/std` tree matches `src/`, every `files` entry of the workspace's 11 manifests resolves, and the comments in the files whose owners had closed were swept. **19 remain**, listed below |
| [D — instructions and vocabulary that do not work](./vocabulary.md) | 5.8, 5.13, + 1.0.3-beta review row 9 | An example header, `docs.md`'s `implement` example, and the comments teaching forms the compiler rejects | `594e262`; `docs.md`'s fences are compiled by `zig build test-docs` since front 14's `758dae4` |
| [Decisions — not work](./decisions.md) | 5.9, 5.5 | License; whether the meta repo needs a gate at all | 5.9 MIT in all seven repos (`af9b5b6` and the six siblings); 5.5a no meta gate; 5.5b a self-contained hook per repo, emilia included (`321981d`) |

## Gate

- [x] `zig build`, `zig build test` from a cold runtime cache, and `zig build test-libs`, green
- [x] Every item fixed, or closed with a written reason in this front's files
- [x] Matching `AGENTS.md` files updated in the same commits
- [x] Each sweep one commit per owning file, landed after the front that owns it

## What it left, and where

Everything below is **1.0.5-beta `08-hygiene`** unless a row names another front. None of it changes
behaviour; all of it is a sweep waiting on a file's owner.

| Residual | Measured |
|---|---|
| **19 comments still name `primitives.d.bp`**, a file that no longer exists (`primitives.bp` does) — `codegen/erlang.zig` 10, `language-server/src/engine.zig` 4, `comptime/infer.zig` 2, `comptime/env.zig` 1, `comptime/stdlib/prelude.zig` 1, `language-server/src/tests/hover.zig` 1. Group C's acceptance ("only the two extension-assertion tests in `resolver.zig` and `discovery.zig`") is therefore **not** met: `02709dd` swept `libs/std` and the files whose owners had closed, and stopped at 01's, 06's and 14's | `grep -rn 'primitives\.d\.bp' modules/ libs/`, 2026-09-18 |
| **One `wat_runtime` mention left**, in `comptime/tests/helpers.zig` — a test source `07-review-backlog` owns. Everything else that matched `wasm3` / `wat_runtime` / `wat_to_wasm` is under `.zig-cache/` | same date |
| **5.13's fixture rewrite** (`comptime/tests/infer_decls.zig:518`) re-records one comptime snapshot, in the directory the checker and the dedup front both move. It lands after both | → `01-checker` / `06-comptime-dedup`, then `08-hygiene` |
| **The comptime runtime's transport errors never reach a diagnostic** — `template_eval.zig` and `decorator_eval.zig` map every one to `EvalFailed`, so `lastTransportError()` is dead. `erl.stderr.log` is documented as shared and best-effort rather than made per-spawn | the two files are the checker's carve-out |
| **`#[@external(node, "…")]` in lower case passes `check` and binds no host, silently** — group D's step 5 decided it should be a located error and registered it; the implementation is the checker's. One language-suite expected failure names it | → `01-checker` |
| **`docs.md:78` needs a `docs-check` directive** before 20's step 1 can land: the fence's `geometry`, `shapes.circle` and `erika` imports are exactly the defect that step fixes, and `zig build test-docs` reds on them. The exact edit is in [`../20-cli-residuals-ii/README.md`](../20-cli-residuals-ii/README.md#blocked-on-docsmd) | → `08-hygiene`, unblocking `10-cli-residuals` |
| **Test comments the backend landings left behind** — `codegen/tests/builtins.zig` ~`:365`, `control_flow.zig` ~`:308`, `features.zig` ~`:866`, `values.zig` ~`:401` (retired front numbers). Read at `ed15323` | → `07-review-backlog`, which owns the test sources |

<a id="ownership-conflicts"></a>

## Ownership conflicts — why the tail exists

This front's behaviour edits owned their files; its comment sweeps did not — and the sweeps were most
of the work.

| Where | What it touches | Whose file |
|---|---|---|
| 5.14, 5.13 | comments in `codegen/erlang.zig`, `codegen/commonJS.zig`, `codegen/beam_asm.zig`, `comptime/infer.zig`, `comptime/env.zig`, `codegen/tests/**` | 01, 06, 08 |
| 5.4, A1 | root `build.zig` (the `test-vscode` step, `build_options`, `libcResolvedTarget`) and `.github/workflows/test.yml` | 05 delivered; this front took these edits |
| A1, A2 | `libs/std/src/builtins.d.bp`, `codegen/crossModule.zig`, `codegen/config.zig`, `comptime/tests/helpers.zig`, `codegen/tests/features.zig` | this front took the `builtins.d.bp` lines; the tests are 08's and 07's |
| E | `comptime/runtime/persistent_erl.zig` | this front |

**The practical rule, and the reason the residual list above is short but real:** a comment-only edit
in another front's file is safe to *make* and expensive to *merge*. Each sweep landed in one commit
per owning file, after the fronts that owned those files — and stopped where a front was still open.

## Notes

- `codegen/wat.zig`'s `KNOWN GAP` block (`$__emit`, `$__compilerError`, `$__binding_ref` "defined by
  the `wat_runtime` prelude") was deleted with `Module.externs` by 1.0.4-beta wasm.
- The `modules/compiler-core/build.zig` header was unmodified `zig init` boilerplate with a global
  `fu`→`f` corruption (`fnction` at `:3, 5, 111, 121`) — the reason it was deleted rather than
  repaired.
