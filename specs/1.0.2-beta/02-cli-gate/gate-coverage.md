# What the gate runs, and what it therefore never sees

Paths are relative to `repository/botopink-lang/` unless a row says otherwise.

## What each build step actually runs

`build.zig` declares seven named steps plus the default `install`. `test` is the only one anything
depends on.

| Step | What it runs | In `zig build test` | In CI | State |
|---|---|---|---|---|
| `test` | `core_tests` (`:111`, cwd `modules/compiler-core`), the lib-agnostic grep gate (`:152`), `lsp_tests` (`:169`), `cli_tests` (`:188`) — and `clean-tmp` (`:127`) as a prerequisite | — | yes, `test.yml` job `test` (ubuntu-22.04 + macos-14 hard, windows-2022 allow-fail) | green |
| `clean-tmp` | reaps `modules/compiler-core/.botopinkbuild/tmp` dirs older than a day | yes | via `test` | fine |
| `test-libs` | `bash scripts/test-libs.sh` → `zig-out/bin/botopink-lib-test` (`:285`) | **no** | yes, `test.yml` job `test-libs`, `-- --target commonJS`, `needs: test`, allow-fail only on windows | **red on every push** — see below |
| `test-vscode` | `bash ../../scripts/test-vscode.sh` (`:301`) | no | no | **the script does not exist** anywhere in the workspace; the meta repo has no `scripts/` directory at all |
| `test-backends` | `bash modules/compiler-cli/tests/backend_exec.sh` (`:315`) | no | no | runs; 1 of its 2 pinned reds is stale |
| `test-bpmp` | `bpmp` unit tests (`:264`) | no | no | deliberate (`:255` comment) |
| `run`, `install` | the CLI | — | `release.yml`/`tag.yml` build only, never test | — |

**Corrected:** `hook-integrity` is not a gate that is missing — it is a name with no referent. No
build step, no workflow and no script in any of the seven repositories mentions it; the only
occurrence in the workspace is the spec text. The meta repository has no `.github/` directory at
all, so nothing gates a submodule bump.

## Where the libraries are compiled

| Repo | Workflow | Trigger | Compiler it builds against | Effect |
|---|---|---|---|---|
| botopink-lang | `test.yml` job `test-libs` | push/PR to `main`/`feat` | itself | `actions/checkout` pulls botopink-lang alone, so the runner's root walk finds only `<checkout>/libs` → **`libs/std` and nothing else** |
| erika | `test.yml` | push/PR to erika's own branches | `vars.BOTOPINK_LANG_REF \|\| 'feat'` (`:63`) — but the identity banner at `:125` prints `\|\| 'main'` | never triggered by a compiler change |
| jhonstart, onze, rakun | `test.yml` | push/PR to their own branches | `vars.BOTOPINK_LANG_REF \|\| 'main'` | same, and `main` lags `feat` |
| vscode-extension | `test.yml` | push/PR to `main`/`feat` | — | pure-TS suite |
| emilia | — | — | — | **no workflows at all** |

None of the sibling workflows can be triggered from botopink-lang (no `repository_dispatch`, no
`workflow_call`). **A change to the compiler is therefore never tested against any library.**

## The local gate

| Repo | `.git/hooks/pre-commit` |
|---|---|
| meta | symlink to `../../scripts/git-hooks/pre-commit` — **dangling**, the meta repo has no `scripts/` |
| **botopink-lang** | **absent** — the repo that ships everything has no local gate |
| erika, jhonstart, onze, rakun, vscode-extension | installed, resolve |
| emilia | absent |

The installed sibling hooks delegate to `$META_ROOT/scripts/git-hooks/lib/test-runner.sh`
(`scripts/git-hooks/pre-commit:13`), which does not exist, so every one of them falls through to
the standalone path. botopink-lang's own `runner-standalone.sh` is the strongest gate in the
workspace — conflict markers, `zig fmt --check`, `zig build`, `zig build test`, then `botopink test`
in each `libs/*` — and it is the one that is not installed. Installing it today would red
immediately: `botopink test` in `libs/std` exits 1.

## What is therefore unchecked

- **A `.bp` library.** `test-libs` is in no gate. Measured at HEAD over the six checked-out
  libraries (`botopink-lib-test --lib-root <copies>`, default targets): **1 passed, 7 failed,
  4 skipped** — emilia green on commonJS; erika and std red on both; jhonstart, onze and rakun red
  on commonJS and skipped on erlang — 7 red cells of 12, not "8/8 red". Since `libs/std` is one of
  the red ones and CI's `test-libs` job sees only `libs/std`, that job is red on `feat` right now.
- **wasm execution, entirely.** `codegen/runtime.zig:553` `executeWat` discards its arguments and
  returns `""`. Every one of the 278 wasm snapshots therefore carries an empty RUN LOG; the backend
  is never run. CI installs wasmtime (`test.yml:82`-`100`) for a step that never uses it. The
  decision belongs to [`../06-wasm/README.md`](../06-wasm/README.md), not here; the gate only has to
  stop claiming coverage it does not have.
- **Program output — partially, not wholly.** "Assertions are return values, never stdout" holds
  for `backend_exec.sh` (`--invoke main`, `erl -eval`) but not for the snapshot suite, which
  compares a captured RUN LOG byte for byte. Measured: non-empty RUN LOGs in `snapshots/codegen/` —
  commonJS 106/279, erlang 117/279, beam 106/278, **wasm 0/278**. So three backends do assert
  stdout, on ~40 % of fixtures; the blind spot is wasm and the ~60 % of fixtures whose program
  prints nothing.
- **The CLI end to end.** All 53 compiler-cli unit tests are in `cli/*.zig`; `main.zig` has none,
  so no flag parser is tested, and no step runs the binary against a real project. That is the whole
  of [`command-contract.md`](./command-contract.md).
- **`modules/compiler-cli/tests/`** — only `backend_exec.sh` is wired (`build.zig:315`):
  - `test_tooling.sh` asserts `grep -q "running 4 tests"` (`:45`). The runner prints
    `TEST main.bp:9 …` per test and `4 passed, 0 failed` — never a `running N tests` banner. The
    script fails on its first assertion, and has since the banner changed. The *behaviours* it
    checks all hold.
  - `std_erlang.sh` documents itself as "currently EXPECTED TO FAIL" and cites
    `tasks/v0.beta.3/specs/`, a path that no longer exists.
  - `mutual_recursion.sh` and `std_erlang.sh` both run an unconditional `zig build`; neither
    honours `BOTOPINK_SKIP_BUILD`, so neither can be wired as-is.
- **`backend_exec.sh`'s pinned reds.** Two escape hatches, both non-fatal by construction.
  `pin_beam_red RECORDS 3 "case-dispatch/lambda codegen"` (`:120`) is **stale**: at HEAD the fixture
  builds, `erlc +from_asm` succeeds and `main:main()` returns `3`, so the cell prints
  `looks FIXED — promote to a hard assert` and passes either way. `pin_run_red MODULES erlang`
  (`:128`) is still genuinely red — `out/main.erl:26:24: function describe/0 undefined`.
- **An orphan module.** `cli/sources.zig:65`-`67` reports a module no `mod` path reaches as a
  `warnDetail`, so `libs/std`'s `primitives.bp` (1019), `reflect.bp` (49) and `types.bp` (79) —
  1147 lines — are skipped by `check`, `build` and `test` alike with three warning lines.

## What the gate should be

**Local, in order** — each step is cheap enough that a failure is found before the next runs:

1. `zig fmt --check` on staged `.zig`, conflict-marker scan (already in `runner-standalone.sh`)
2. `zig build` — the CLI and the LSP link
3. `zig build test` — the compiler suite, **with `modules/compiler-core/.botopinkbuild/runtime-cache`
   deleted** for the run that decides a merge
4. `zig build test-cli` (new) — `modules/compiler-cli/tests/*.sh`, every script, each honouring
   `BOTOPINK_SKIP_BUILD`
5. `zig build test-libs` — every library the checkout can see, per target, with **no** skip that is
   not a missing runtime
6. `zig build test-backends` — pinned reds converted to hard asserts or deleted

Install it as botopink-lang's `pre-commit`, and in the meta repo replace the dangling symlink with a
hook that runs the same gate in `repository/botopink-lang` plus `botopink test` in each checked-out
sibling.

**In CI**, one workflow in botopink-lang with the sibling repos checked out:

| Job | Steps | Runners |
|---|---|---|
| `test` | zig, OTP 28, node, wasmtime → steps 2–4 above | ubuntu + macos hard, windows allow-fail |
| `libs` | `needs: test`; checkout botopink-lang, then `actions/checkout` each of `botopink/{emilia,erika,jhonstart,onze,rakun}` at `feat` into `repository/<name>/`; `zig build test-libs` over all targets | ubuntu hard |
| `backends` | `needs: test`; `zig build test-backends` | ubuntu hard |

A library failure must surface as the job's own failure with the library's name and the failing
module's diagnostic in the log — which is exactly what the C1/C4 fixes in
[`command-contract.md`](./command-contract.md) make possible: today a library can fail to compile
and `botopink test` still exits 0.

## Cost, measured

Measured on the dev workstation, cold caches.

| Piece | Measured |
|---|---|
| `botopink check` / `test` per library | 105–460 ms each; rakun 17 ms (fails at dependency resolution) |
| `botopink-lib-test` over 6 libraries × 2 targets | **3.1 s** total (2.3 s for commonJS alone) |
| `zig build test`, warm runtime cache | ~17 s (`AGENTS.md`) |
| one child-process spawn | `node` 16 ms, `wasmtime` 2 ms, `erl` 79 ms, `erlc` 131 ms |
| entries in the runtime cache a cold run must re-execute | 532 |

So the libraries cost **seconds**, not minutes: the reason to add them to the gate is coverage, not
that they are expensive. The expensive piece is the cold cache — 532 re-executions at the unit costs
above put a cold `zig build test` in the region of a minute rather than 17 s, which is the price of
the rule that the merge-deciding run is cold.

## Ordering against the other fronts

Widening the gate reds things that are red today and were simply not looked at: `libs/std`
(owned by [`../03-std-surface/`](../03-std-surface/README.md)), erika and jhonstart
(residual `unbound_var` after [`../01-comptime-dispatch/`](../01-comptime-dispatch/README.md)),
rakun's missing `server` dependency (the library-repos front). This front therefore lands the gate
*machinery* and the command contract; whether each library is a hard assert or a named, counted
skip is the last acceptance row, and it flips to hard as those fronts land.
