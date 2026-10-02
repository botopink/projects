# Front 131 — gate-build-cache: every build cache inside `.botopinkbuild/`, and the dependency closure typed once

**Priority:** high — decision 225: a cache is wiped by deleting `.botopinkbuild/`, the package under
test is never served from one, and a dependency closure is type-checked once per run instead of once
per member.
**Depends on:** `115-gate-perf` (its erlang verdict cache, `.beam` cache and cell schedule are the
stores this front moves), and the gate green on `feat` (a red cell's time is not the gate's time).
**Owns:** `modules/compiler-cli/src/cli/libs.zig` (`userCacheDir` — deleted), `compiler-cli/src/cli/build.zig`
(`checkErlang`'s `cache_dir`), `compiler-cli/src/cli/test_cmd.zig` (`beamCacheDir`), `compiler-cli/src/cli/clean.zig`
(`botopink clean`), `modules/lib-test-runner/src/schedule.zig` (`durations.tsv`), the new closure cache in
`compiler-cli` and the entry in `compiler-core` that takes a pre-typed package, `scripts/gate.sh`
(`--cold`), `modules/compiler-cli/tests/cli_contract.sh` (the cache sections) and the `AGENTS.md` of
each directory touched.
**Does not touch:** any stage's content (which cells, which targets); the checker's rules; the
emitters; snapshots — a cached build that emits a different byte than an uncached one is this
front's defect, never a re-record.

---

## Problem

Two things, one rule (decision 225).

**1. Three stores live outside the project, where deleting `.botopinkbuild/` does not reach them.**
`libs.userCacheDir` (`libs.zig:63-78`) answers `$XDG_CACHE_HOME/botopink/<sub>` or
`$HOME/.cache/botopink/<sub>`, shared by every checkout, worktree and gate of the machine:

| Store | Path today | Written by | Reaped |
|---|---|---|---|
| erlang verdict cache | `~/.cache/botopink/erlcheck/<k[0..2]>/<k>.ok` | `build.zig:123` `checkErlang` | by age |
| `.beam` cache | `~/.cache/botopink/beam/` | `test_cmd.zig:391` `beamCacheDir` | by age |
| cell durations | `~/.cache/botopink/lib-test/durations.tsv` | `lib-test-runner/src/schedule.zig:11-71` | never |

`botopink clean` does not reach them (`libs.zig:69`, `test_cmd.zig:387`), and `gate.sh --cold`
deletes only `modules/compiler-core/.botopinkbuild/runtime-cache`. A "cold" gate therefore still
answers erlang verdicts and `.beam` files from a previous run.

**2. Every member re-checks its whole dependency closure.** `botopink test` of each rakun member
type-checks and emits std, validation and rakun again before its own sources; `onze-cli`'s tests run
`onze build`, which compiles onze-server → rakun → validation once more. Measured by 115: the Zig
compile of a cell's closure is 1–5 s of ReleaseSafe CPU (`emilia-borders`: 1.4 s commonJS, ~5 s
erlang); the `test-libs` stage is 2m46s wall, 1529 CPU-s on the integrated tip (shared machine). How
much of that is the repeated closure is not measured — step 1 measures it.

## Current state

- The three stores above exist and are content-keyed (a key mismatch is a miss, never a wrong
  answer); none is under `.botopinkbuild/`.
- No closure cache exists: `compiler-core` takes sources only; there is no pre-typed package input.
- A dependency's emitted modules are not a function of the package alone: `crossModule.CrossModule`
  is built over the whole program, and an owner exports only what another module of the build
  imports (`imported` — a record's assoc fns, an erlang `externalWrapperForm` for an imported
  `pub declare fn`). The same rakun module emitted for two members that import different names
  differs in its export list, so an emitted-module entry keyed by the package alone would serve
  bytes an uncached build does not write.
- The typed export tables a consumer reads are in-memory graphs of the session arena
  (`comptime.compile`'s registries: `*T.Type` per export, the `ast.DeclKind` of each type, the
  `ast.FnDecl` bodies of templates and decorators, `ImplementDecl`s, the decorator reflection and
  the default DSL); none has a serialized form.

## Steps

### Step 1 — measure the closure

For `test-libs` on the gate's tip: per cell, the wall and CPU-seconds of the dependency closure
(check + emit) against the member's own sources, from `--trace`-style timing the runner already
prints or a counter added for the run. The table goes in this README.

**Acceptance:**
- [x] the table (rakun members, onze-cli, onze-server, jhonstart, emilia, validation) with the load
      and the commit; the share of `test-libs` CPU that is a repeated closure

**Measured.** `zig build test-libs -Doptimize=ReleaseSafe` (both targets, 123 cells passed) on
botopink-lang `e5ac9a21`, rakun `9471a03`, onze `72dfbe1`, emilia `29548a6`, jhonstart `22df151`;
16 CPUs, load average 22 at the start and 57 at the end (a shared machine). The stage took 5m37s
wall and 2 233 CPU-s (every child: `botopink`, `erl`, `node`). A counter added for the run (not
kept) timed each module's check (`comptime.compile`'s per-module body, transform included) and emit
(each backend's per-module loop) with the thread's CPU clock, and split them by whether the module
is one of the cell's own (`src/` + `test/`) or of its closure (std, bundled packages, dependencies).
"Processes" counts every `botopink` the cell spawned (rakun's and onze-cli's build tests spawn
`botopink build` per fixture); a row sums both targets.

| Cell | `botopink` processes | closure check + emit, CPU-s | own check + emit, CPU-s | closure, wall-s | `botopink` process CPU-s |
|---|---|---|---|---|---|
| onze-cli | 26 | 34.3 | 2.7 | 43.7 | 59.9 |
| onze-server | 2 | 2.8 | 0.0 | 3.3 | 9.8 |
| rakun members (36 rows) | 189 | 58.0 | 4.1 | 103.9 | 97.0 |
| — rakun-scheduling | 29 | 10.4 | 0.5 | 22.6 | 17.4 |
| — rakun-data | 25 | 8.5 | 0.6 | 20.0 | 14.2 |
| — rakun-messaging | 14 | 5.1 | 0.3 | 11.8 | 8.4 |
| jhonstart | 2 | 0.2 | 0.2 | 0.2 | 0.6 |
| jhonstart-emilia | 2 | 2.0 | 0.1 | 2.5 | 8.7 |
| emilia | 2 | 0.0 | 1.7 | 0.0 | 8.3 |
| an `emilia-*` example (each of 15) | 2 | 1.7–2.0 | 0.1 | 2.0–2.5 | 7.9–8.6 |
| validation | 2 | 0.1 | 0.3 | 0.1 | 0.6 |
| **stage total** (313 processes) | | **144.2** (check 99.2, emit 45.0) | **12.3** | | **378.3** |

348 distinct closure modules; compiling each once per target costs ~4 CPU-s, so the **repeated
closure is ~140 CPU-s, 6.3 % of the stage's 2 233 CPU-s** (and 37 % of the compiler's own 378
CPU-s). Its wall share is smaller still: the cells run side by side, and onze-cli (the stage's long
pole) spends 43.7 s of its wall in the closure. The rest of the stage is the programs and the OTP
compile (`erl`, `node`, `precompileErlang`), which a closure cache does not touch.

### Step 2 — every store under `.botopinkbuild/cache/`

The stores move to `<root>/.botopinkbuild/cache/<store>/`, `<root>` the **workspace root** of the
package being built (the directory whose `botopink.json` lists the workspace members), or the
project root when there is no workspace — so the members of one library repository share one cache,
and deleting that `.botopinkbuild/` deletes all of it. `libs.userCacheDir` is deleted; no store
reads `XDG_CACHE_HOME` or `HOME` (the `bpmp` package store is a package store, not a build cache,
and stays). `botopink clean` deletes `.botopinkbuild/` whole. `gate.sh --cold` deletes the
`.botopinkbuild/cache/` of every root the gate reads (the compiler checkout and each sibling
library repository) before stage 2.

```sh
repository/rakun/.botopinkbuild/cache/erlcheck/…     # was ~/.cache/botopink/erlcheck
repository/rakun/.botopinkbuild/cache/beam/…         # was ~/.cache/botopink/beam
repository/rakun/.botopinkbuild/cache/closure/…      # step 3
rm -rf repository/rakun/.botopinkbuild               # every cache of rakun gone
```

**Acceptance:**
- [ ] `git grep -n 'XDG_CACHE_HOME\|\.cache/botopink' modules` names only the `bpmp` store — it
      also names the language server's `~/.cache/botopink-lsp/{template,std}` (`server.zig`: the
      editor's template-eval scratch and materialized std, outside this front's ownership) and
      `cli_contract.sh`'s rows that point `HOME`/`XDG_CACHE_HOME` at a scratch directory to assert
      nothing is written there; no compiler or runner store reads either variable
- [x] `cli_contract.sh`: a build writes its verdicts under `<root>/.botopinkbuild/cache/erlcheck/`;
      after `rm -rf <root>/.botopinkbuild` the next build compiles every module again (no hit)
- [x] `botopink clean` leaves no `.botopinkbuild/` and no file under `$HOME/.cache/botopink`
- [x] `gate.sh --cold` prints the cache roots it deleted

**Built.** `libs.cacheRoot` / `libs.cacheDir` (`compiler-cli/src/cli/libs.zig`) answer
`<root>/.botopinkbuild/cache/<store>`, `<root>` the enclosing workspace's directory
(`ProjectConfig.workspace`) else the project's; `libs.userCacheDir` is gone. `build.zig`'s
`checkErlang` reads `cache/erlcheck`, `test_cmd.zig`'s `beamCacheDir` `cache/beam`. The runner's
`schedule.zig` keeps one `cache/lib-test/durations.tsv` per cache root (`schedule.cacheRoot`: the
cell's library's workspace root, else the library), reads them all before ordering and writes each
root's own cells back. `botopink clean` deletes `out/` and `.botopinkbuild/` and, in a workspace
member, the workspace root's `.botopinkbuild/cache/` (printed as its own `Removed` line).
`gate.sh --cold` deletes every `.botopinkbuild/cache/` under the compiler checkout and each sibling
`repository/*`, printing `gate: --cold deleted <dir>` for each. `cli_contract.sh` runs the
verdict-cache rows with `HOME`/`XDG_CACHE_HOME` on a scratch directory and adds the workspace row
(a member's verdicts under the workspace root, none under the member; `clean` in the member deletes
both). `test-libs --lib validation|rakun|onze-cli` with an empty cache and warm: green, same counts
(2 / 1 + 1 audit / 2 passed); each root then holds `cache/beam` and `cache/lib-test`.

A fixture project a library's tests build under `BOTOPINK_TEST_TMPDIR` (rakun's and onze-cli's
`botopink build` per fixture) is a project of its own outside any workspace, so its cache root is
the fixture directory: the verdict cache no longer carries across those builds, which the
machine-wide store did.

### Step 3 — the dependency closure, typed once

A dependency package (never the package under test, never a `path`/workspace member being edited
in the same run — see the rule below) is checked and emitted once per run and stored under
`<root>/.botopinkbuild/cache/closure/<k>/`: its emitted modules and its typed export tables. `k` is
the SHA-256 of the package's source bytes (every file its manifest lists), of the keys of its own
dependencies (so a change in std is a new key for every package above it), of the compiler binary's
build id and of the target. `compiler-core` gains the entry that takes a pre-typed package as input
in place of its sources; the checker reads its export tables as it reads a checked module today.

**The rule (decision 225).** The package under test is always compiled from its sources: its
`.botopinkbuild/cache/closure/` entry is neither read nor written. Only what it depends on is
served from the cache.

**Acceptance:**
- [ ] `zig build test-libs` with an empty cache and warm: the same cell lines, the same passed
      count, and byte-identical emitted modules for every cell (a script diffs the `out/` trees)
- [ ] one byte changed in `libs/std/src/collections.bp` → every entry that includes std is a miss,
      nothing stale served
- [ ] the compiler rebuilt with one changed emitter line → every entry a miss
- [ ] the package under test edited between two runs → its own result reflects the edit with no
      cache entry involved (a cell asserting a value the edit changes)
- [ ] `test-libs` CPU-seconds against step 1's table, on the same machine and load class

## Gate

- [ ] `scripts/gate.sh --cold` green on the integrated branch, under the budget of `115`
- [ ] every `AGENTS.md` of a touched directory updated in the same commit (`compiler-cli/src/cli/`,
      `lib-test-runner/`, `scripts/`, `compiler-core/` for the pre-typed entry)
- [ ] commits on `front/131-gate-build-cache`; no push, no merge — landing is the coordinator's step

## Blast radius

- Every checkout and worktree gets its own cache: a fresh worktree compiles everything once (the
  machine-wide sharing of today goes, by decision 225). `.gitignore` of every repository already
  ignores `.botopinkbuild/`; check the five libraries and the meta.
- The five libraries' pre-commit runner and CI rows run `botopink-lib-test` from a scratch directory
  with `BOTOPINK_LIB_ROOTS`: their cache root is the library repository's own `.botopinkbuild/`.
- No snapshot moves.

## Notes

- Replaces `115`'s step 2 closure question (`gate-k`, answered by decision 225); `115` closes on
  what it built, and its erlang verdict cache, `.beam` cache and schedule move here.
- `gate-l` (CI build mode) is a separate question; this front does not edit `.github/workflows/`.
