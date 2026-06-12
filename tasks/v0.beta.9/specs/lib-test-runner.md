# lib-test-runner — a Zig module that runs every `libs/` project's tests per target

**Slug**: lib-test-runner
**Depends on**: nothing (uses the existing `botopink test` CLI; richer targets arrive via [[stdlib-backends-parity]] F5)
**Files**: `modules/lib-test-runner/build.zig`, `modules/lib-test-runner/build.zig.zon`, `modules/lib-test-runner/src/*.zig`, `build.zig` (workspace — wire the executable + a `test-libs` step), `modules/AGENTS.md` (tree + table)
**Touches docs**: `modules/lib-test-runner/AGENTS.md` (new), `modules/AGENTS.md`
**Status**: pending

> **Goal.** One Zig executable in `modules/` that discovers every `.bp` project
> under `libs/`, runs its test suite on each requested backend by invoking
> `botopink test --target <t>`, aggregates the results into a lib×target matrix,
> and **exits non-zero if any cell fails** — the missing CI gate for the lib
> ecosystem. Today each lib is tested by hand (`cd libs/<x> && botopink test`); the
> std-backend specs reference a `std_erlang.sh` that does not exist in `scripts/`.
> This replaces both with a real, buildable runner.

## Context — what exists

- **`botopink test`** (`modules/compiler-cli/src/cli/test_cmd.zig`) already compiles
  a single project in test mode, runs each module's `test {}` blocks, **aggregates
  exit codes, and returns non-zero on failure**. It discovers tests in `src/`
  (inline `test "…" {}` blocks) and `test/*_test.bp` suites, resolves declared
  `dependencies` from `libs/`, and accepts `--target <t>` / `--filter <substr>`.
- **Targets** (`config.Target`): `commonJS`, `erlang`, `beam`, `wasm`. **`botopink
  test` currently runs only `commonJS` (node) and `erlang` (escript)** — beam/wasm
  return a "currently supports only…" error (the wasm runner is
  [[stdlib-backends-parity]] F5).
- **Libs** under `libs/`: `client`, `erika`, `jhonstart`, `onze`, `rakun`,
  `server`, `std` — each with a `botopink.json`. Tests today: `libs/rakun/test/*`,
  `libs/onze/test/*`, and inline `test` blocks (erika ~30). Some libs are
  declaration-only / have no test blocks yet.
- **Build**: the workspace `build.zig` wires `compiler-core` (lib) → `compiler-cli`
  (`botopink` exe) + `language-server`. `zig build test` runs the Zig suites + the
  lib-agnostic grep gate. A new module is added exactly like the others
  (`addExecutable`, own `build.zig`/`.zon`/`AGENTS.md`).

## Design — orchestrate the existing CLI, do not reimplement test running

The runner **shells out to the installed `botopink` binary** (`botopink test
--target <t>`) with `cwd` set to each lib directory. This is deliberate over
linking `test_cmd.run` directly: `test_cmd` reads `botopink.json` and writes
`.botopinkbuild/` relative to `std.Io.Dir.cwd()`, so per-lib isolation falls out of
spawning a child with that lib as its working directory — the same thing CI would
do — with no global-cwd juggling. The Zig module's job is **discovery +
fan-out + aggregation + exit code**, nothing the compiler already does.

### CLI surface (the new executable, e.g. `botopink-lib-test`)
```
botopink-lib-test [--target <t>[,<t>…] | --target all] [--lib <name>] [--strict] [--filter <s>]
```
- `--target` — repeatable or comma-separated; accepts `commonJS|erlang|beam|wasm`
  **plus the alias `node` → `commonJS`**; also accept `--target=<t>` (the `=` form,
  matching the user's `bp test --target=erlang`) in addition to `--target <t>`.
  Default: `commonJS,erlang` (the two `botopink test` runs today). `all` expands to
  every *supported* target.
- `--lib <name>` — restrict to one lib under `libs/`; default: every lib with a
  `botopink.json`.
- `--filter <s>` — forwarded to `botopink test --filter`.
- `--strict` — treat an unsupported target (beam/wasm) as a **failure** instead of
  a skip (default: skip with a warning, so the gate stays green until F5 lands).

## Steps

### F0 — the module skeleton
- [ ] `modules/lib-test-runner/` with `build.zig` + `build.zig.zon` mirroring
      `compiler-cli`'s shape; an `AGENTS.md` linked from `modules/AGENTS.md` (tree +
      package table row).
- [ ] Workspace `build.zig`: `addExecutable` (name e.g. `botopink-lib-test`),
      `installArtifact`, and a **`zig build test-libs`** step that depends on the
      `botopink` install (so the binary exists) and runs the artifact with
      `setCwd(b.path("."))` (repo root, so `libs/` resolves). `b.args` forwarded so
      `zig build test-libs -- --target erlang --lib rakun` works.

### F1 — discovery
- [ ] Enumerate `libs/*/` directories that contain a `botopink.json`. Skip
      `--lib`-excluded ones. Determine "has tests": a `test/` dir with `*.bp`, or a
      `src/**/*.bp` containing a `test` block. A lib with no tests is **reported as
      `no tests` (green skip)**, never a failure (matches `botopink test`'s own
      "no test blocks found" → exit 0).

### F2 — fan-out + per-cell run
- [ ] For each `(lib, target)` in the requested set, locate the `botopink` binary
      (the just-built `zig-out/bin/botopink`; allow an env/flag override for a
      custom path), spawn `botopink test --target <t> [--filter …]` with
      `cwd = libs/<lib>`, inherit stdio so the child reports inline, and capture the
      exit code.
- [ ] Unsupported target (the child prints "currently supports only…" / returns 1
      for beam/wasm): classify as **skipped-unsupported** unless `--strict`. Don't
      let a known-unsupported backend redden the matrix by default.

### F3 — aggregation + exit code
- [ ] Print a final lib×target matrix: `✓` pass, `✗` fail, `–` no-tests, `~`
      skipped-unsupported, with a one-line summary (`N passed, M failed, K skipped`).
- [ ] **Exit non-zero iff at least one cell is `✗`.** A failed `botopink test`
      (a red `.bp` test) must make `botopink-lib-test` — and therefore `zig build
      test-libs` — fail. This is the core acceptance criterion.

### F4 — wire it in (optional gate)
- [ ] Document `zig build test-libs` in `modules/AGENTS.md` and the root
      `AGENTS.md`. Do **not** add it to the default `zig build test` (it needs
      `node`/`escript` on PATH, which the Zig-only gate doesn't assume) — keep it a
      separate, CI-/pre-commit-invokable step.

## Test scenarios

```
run  ---- `zig build test-libs` runs every lib on commonJS+erlang; all green → exit 0
run  ---- a deliberately failing test in libs/onze → matrix shows ✗, exit != 0
run  ---- `--target erlang` runs only erlang; `--lib rakun` runs only rakun
run  ---- `--target=node` aliases to commonJS (and the `=` form parses)
run  ---- a lib with no test blocks shows `–` and does NOT fail the run
run  ---- `--target beam` → `~ skipped-unsupported`, exit 0; with `--strict` → exit 1
unit ---- arg parsing (target list, =-form, node alias) + lib discovery have Zig tests
```

## Notes

- **Why a Zig module, not a shell script:** it ships in the build graph (`zig build
  test-libs`), is cross-platform, and reuses the workspace's target enum semantics —
  the project already deleted ad-hoc `scripts/*.sh` test runners in favour of real
  tooling. Memory: [[feedback_everything_english]] (module is English-only).
- **Forward-compatible with backend parity:** the moment `botopink test` learns
  `beam`/`wasm` ([[stdlib-backends-parity]] F5 wasm runner), those targets stop
  being skipped — the runner needs no change, only the default/`all` target set
  widens. Keep the unsupported-target detection driven by the child's exit, not a
  hard-coded list, so it self-updates.
- **Isolation:** each child writes its own `libs/<lib>/.botopinkbuild/test-out/`;
  the runner touches no compiler internals. No new core code, no lib coupling.
- Dependencies between libs (e.g. a consumer importing `from "rakun"`) resolve
  through `botopink test`'s existing `libs/` dependency loader — the runner does not
  re-implement dependency resolution.
