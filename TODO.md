# test-speed-tmp-consolidation

> Spec: [`tasks/v0.beta.20/specs/test-speed-tmp-consolidation.md`](../../tasks/v0.beta.20/specs/test-speed-tmp-consolidation.md) — full content lives there.

## Baseline

- meta `feat`: `2231f2d` (`chore(submodule): bump bot-lang ffe7aff → 269cd95`).
- bot-lang `feat`: `269cd95` (3 wasm snap fixes from snap-audit F1.c→b promotion).
- Today's leaked siblings of `modules/compiler-core/`:
  ```
  .botopinkbuild
  .tmp-exec-94a10fc927be8d94
  .tmp-exec-922f9ea881df7003
  .tmp-exec-bec56372251b9551
  .tmp-exec-f4a8d4ee28740b17
  ```

## Phases (from spec F0–F4)

- [x] **F0 — `runtime.zig` rewrite** (`modules/compiler-core/src/codegen/runtime.zig:41-51`)
  - Replace `.tmp-exec-{x}` prefix with `.botopinkbuild/tmp/{x}` (single callsite in `makeScratchDir`).
  - Grow buffer from `[64]u8` to `[96]u8`.
  - `TMP_ROOT` + `makeScratchDir` exposed `pub` so the F3 pin test can pin them directly.
- [x] **F1 — `.gitignore` cleanup** (`repository/botopink-lang/.gitignore`)
  - Removed the now-dead `**/.tmp-exec-*/` rule.
  - No leftover `.tmp-exec-*/` siblings to sweep on this worktree.
- [x] **F2 — `build.zig` `clean-tmp` step** (`repository/botopink-lang/build.zig`)
  - `sh -c 'mkdir -p .botopinkbuild/tmp && find .botopinkbuild/tmp -mindepth 1 -maxdepth 1 -type d -mtime +1 -exec rm -rf {} +'` (cwd `modules/compiler-core/`).
  - Exposed as standalone `zig build clean-tmp` step, and wired as dep of `run_core_tests` so it runs at the start of every `zig build test` cycle.
- [x] **F3 — `runtime_scratch.zig` pin** (`modules/compiler-core/src/codegen/tests/runtime_scratch.zig`)
  - 3 tests: path-layout pin (`.botopinkbuild/tmp/<hex>/`), cleanup-on-success, no-root-sibling-on-crash.
  - Registered in `codegen/tests.zig` barrel.
- [x] **F4 — AGENTS + CHANGELOG sweep**
  - `modules/compiler-core/src/codegen/AGENTS.md` — `runtime.zig` row gained the layout + reap contract.
  - `repository/botopink-lang/AGENTS.md` — `clean-tmp` listed in Workspace commands + scratch-layout paragraph.
  - `repository/botopink-lang/CHANGELOG.md` — v0.beta.20 entry under `Changed (test-speed-tmp-consolidation)`.
  - `tasks/v0.beta.20/status.md` — row flipped to **done — pending merge**.
  - `tasks/v0.beta.20/specs/test-speed-tmp-consolidation.md` — status field flipped.

## Out of scope (tracked in spec → potential v0.beta.21)

- Aggressive cache reuse (hash-keyed dir reuse).
- Parallel test worker subprocess pool.
- `erl_crash.dump` suppression via `ERL_CRASH_DUMP=/dev/null`.

## Exit gate

- Zero `.tmp-exec-*/` dirs after `zig build test` on a fresh clone.
- All per-test scratch under `<compiler-core>/.botopinkbuild/tmp/<hex>/`.
- `runtime_scratch.zig` pin tests green on every backend.
- `git status` clean after `zig build test`.
- `clean-tmp` step reaps leaks >1 day; manual `zig build clean-tmp` works.
- AGENTS.md per affected module updated in the same commit as code.
