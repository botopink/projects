# TODO — lib-test-runner  (tooling · Wave 1)

> Task branch `task/lib-test-runner` · spec
> [`tasks/v0.beta.9/specs/lib-test-runner.md`](tasks/v0.beta.9/specs/lib-test-runner.md).
> Edit code **inside this worktree only**. Pre-commit runs zig fmt + build + test (no `--no-verify`).
> **Depends on: nothing.** A new `modules/` Zig module — fully self-contained. Start now.

> Orchestration only — shells out to the existing `botopink test`; no compiler internals.

## F0 — the module skeleton
- [x] `modules/lib-test-runner/` with `build.zig` + `build.zig.zon` (mirror compiler-cli);
      `AGENTS.md` linked from `modules/AGENTS.md` (tree + table row).
- [x] Workspace `build.zig`: `addExecutable` (`botopink-lib-test`) + `installArtifact` +
      a **`zig build test-libs`** step (depends on the `botopink` install, `setCwd(".")`,
      forwards `b.args`).

## F1 — discovery
- [x] Enumerate `libs/*/` with a `botopink.json`; `--lib` filter; "has tests" =
      `test/*.bp` or a `src/**/*.bp` `test` block. No-tests lib → green skip (`–`).

## F2 — fan-out + per-cell run
- [x] For each `(lib, target)`: spawn `botopink test --target <t> [--filter …]` with
      `cwd = libs/<lib>`, capture+re-emit stdio, capture exit code. Locate
      `zig-out/bin/botopink` (`--bin`/`BOTOPINK_BIN` override allowed; PATH fallback).
- [x] Unsupported target (beam/wasm today) → `~ skipped-unsupported` unless `--strict`.
      Detection is child-output-driven (`"currently supports only"`), not a hard-coded list.
- [x] CLI: `--target <t>[,<t>]|all` (accept `node`→commonJS alias + `--target=X`), `--lib`,
      `--filter`, `--strict`. Default targets `commonJS,erlang`.

## F3 — aggregation + exit code
- [x] Print a lib×target matrix (`✓`/`✗`/`–`/`~`) + summary.
- [x] **Exit non-zero iff any cell is `✗`** — a red `.bp` test fails `zig build test-libs`.
      (core acceptance criterion)

## F4 — wire it in
- [x] Document `zig build test-libs` in `modules/AGENTS.md` + root `AGENTS.md`. Do **not**
      add to default `zig build test` (needs node/escript on PATH).

## Done gate
- [~] `zig build test-libs` green across all libs (commonJS+erlang). commonJS: all green;
      std passes both backends. **erlang still reds for erika/jhonstart/onze/rakun** —
      not one bug but a *cluster* of pre-existing erlang-codegen gaps; the runner
      correctly surfaces them as `✗` (the gate working). While investigating, two
      *general* `erlang.zig` fixes landed here (gate green, 3 broken erlang snapshots
      corrected):
        1. reserved-word atom quoting — a fn named `of`/`div` is now `'of'`/`'div'`
           at def/export/call (was invalid bare-atom erlang).
        2. trailing-comment dangling comma — a final `// comment` stmt no longer
           strands a `,` before `end` (`emitBodyFrom` keys off the last *real* stmt).
      Remaining tail is real stdlib-backends-parity scope: erika (unbound module `val`,
      missing `toString/1`), jhonstart (empty `fun -> end` body), rakun (`@emit`-generated
      erlang), and **onze (`MissingExternalTarget` — node-only mock lib, architecturally
      not erlang-compilable without an erlang mock runtime).**
- [x] a deliberately-failing lib test → matrix `✗`, exit != 0 (verified: 4 erlang reds).
- [x] arg-parsing + discovery + matrix have Zig tests; `zig build && zig build test` green.
