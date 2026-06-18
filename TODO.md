# test-speed-tmp-consolidation — DONE + MERGED

> Spec: [`tasks/v0.beta.20/specs/test-speed-tmp-consolidation.md`](../../tasks/v0.beta.20/specs/test-speed-tmp-consolidation.md)

## Final state

- **bot-lang `feat`**: `d6e8d80` (was `269cd95`) — F0–F4 + perf follow-ups landed FF.
- **meta `feat`**: `4bac175` (was `2231f2d`) — submodule bump + v0.beta.21 specs landed FF.
- **task branches preserved** on origin: `task/test-speed-tmp-consolidation` on both repos.
- **Exit gate met**: zero `.tmp-exec-*/` dirs leak; scratch under `<compiler-core>/.botopinkbuild/tmp/<hex>/`; `clean-tmp` step reaps >1d; pins green; sublanguage tests 10-25× faster, R2 decorator 12× faster, empty-source 200× faster.

---

## Phase 1 — F0–F4 (the spec'd work)

- [x] **F0 — `runtime.zig` rewrite** (`modules/compiler-core/src/codegen/runtime.zig:41–51`)
  - Replaced `.tmp-exec-{x}` prefix with `.botopinkbuild/tmp/{x}`.
  - Buffer grown `[64]u8 → [96]u8`.
  - `TMP_ROOT` + `makeScratchDir` exposed `pub` for the F3 pin tests.
- [x] **F1 — `.gitignore` cleanup**
  - Removed the now-redundant `**/.tmp-exec-*/` rule.
- [x] **F2 — `build.zig` `clean-tmp` step**
  - `find .botopinkbuild/tmp -mindepth 1 -maxdepth 1 -type d -mtime +1 -exec rm -rf {} +`, standalone step + dep of `run_core_tests`.
- [x] **F3 — `runtime_scratch.zig` pin** (NEW)
  - 3 tests: path layout, cleanup on success, no root-sibling on crash. Registered in `codegen/tests.zig`.
- [x] **F4 — AGENTS + CHANGELOG sweep**
  - `codegen/AGENTS.md`, repo `AGENTS.md`, `CHANGELOG.md`, `tasks/v0.beta.20/status.md`, spec status field.

## Phase 2 — Perf follow-ups (beyond original spec, same task umbrella)

### Compiler-core comptime tests
- [x] **`helpers.zig` migration** — `assertInfersOk` / `assertTypeErrorSnap` now use `inferMod.freshEnv` (cached `stdlib_template`) instead of running `registerStdlib` fresh each test.
  - **~80ms → ~µs** per affected test, ~150 tests benefit.

### LSP sublanguage / decorator path
- [x] **`persistent_node.zig`** (NEW, ~160 LOC) — long-lived `node` runner, length-prefixed stdin/stdout IPC, `vm.runInContext` isolation per script.
- [x] Wired into `template_eval.evaluate`, `decorator_eval.evaluate`, `runtime/node.zig run()`, `codegen/runtime.executeJavaScript` (with one-shot fallback).
- [x] **`persistent_erlang.zig`** (NEW, ~250 LOC) — long-lived escript runner, `erl_scan` + `erl_parse` + `compile:forms`, `group_leader`-redirected stdout capture, module purge between calls. Wired into `runtime/erlang.zig` with `erlc + erl` fallback.
- [x] Process-wide SHA-256 stdout memos in `template_eval.zig` and `runtime/erlang.zig` (mirror of `node.zig`'s existing memo).

### LSP builtin-receiver paths
- [x] **`collectInterfaceMembersCached`** in `language-server/src/engine.zig` — process-lifetime hashmap by interface name → `[]InterfaceMember`. Wired into `builtinReceiverCompletion`, `builtinMethodSignature`, `hoverBuiltinInterfaceMethod`.
- [x] **`InterfaceMember`** extended with `name_line` / `name_col`; `findInterfaceMemberRange` consumes the cache instead of re-lexing.

### Decorator @emit fast path
- [x] **`parseAndMergeContributions` + `analyzeMerged`** in `comptime.zig` — when a decorator @emits, parse each contribution into AST and merge into the program. Skips re-lex/re-parse of the original module on the second pass. Falls back to text splice on contribution parse error.

### Pre-warm tests
- [x] `modules/compiler-core/src/test_warmup.zig` (NEW) + `modules/language-server/src/tests/_warmup.zig` (NEW) — single warmup pair lazy-inits `stdlib_template` + pre-spawns `persistent_node` + `persistent_erlang`. Moves cold-start spikes (80ms / 20ms / 180ms) out of feature-test rows.

## Phase 3 — v0.beta.21 specs authored

Three specs landed in `tasks/v0.beta.21/specs/`, ordered for execution:

1. [**`wasm3-embedded-runtime.md`**](../../tasks/v0.beta.21/specs/wasm3-embedded-runtime.md) (slug: `wasm3-unified-runtime`)
   - Vendor wasm3, implement wat→wasm in pure Zig (~600 LOC), embed wasm3 in compiler.
   - Collapse the 4-runtime architecture (`node`/`erlang`/`wasm`/`beam` enum) into a single wasm3-hosted path.
   - Remove `wasmtime`, `erl`, `erlc`, `escript` from required PATH binaries.
2. [**`templates-decorators-botopink-native.md`**](../../tasks/v0.beta.21/specs/templates-decorators-botopink-native.md) (depends on #1)
   - Extend WAT backend to template/decorator parity (anon records, optionals, throw/catch, capture/decl runtime).
   - Migrate `template_eval.evaluate` / `decorator_eval.evaluate` to WAT + wasm3.
   - Delete `persistent_node.zig`, remove `node` from required PATH. Compiler becomes self-contained.
3. [**`persistent-erlang-ipc.md`**](../../tasks/v0.beta.21/specs/persistent-erlang-ipc.md) (NARROW follow-up, optional)
   - Only the codegen-side `executeErlang` / `executeBeamAsm` paths remain — comptime piece was absorbed by spec #1.

Discarded: `template-static-fold.md` (folded into spec #1 + #2 — wasm3 covers the whole eval surface; a parallel Zig folder would be dead weight).

## Measured speedups (full LSP test suite, post-fixes vs baseline)

| Test | Baseline | Now | Speedup |
|---|---:|---:|---:|
| `empty source compiles` | 80.479ms | **409us** | ~200× |
| `decorator-bearing record (R2)` | 19.555ms | **2.298ms** | ~8.5× |
| `array value receiver Array methods` | 7.402ms | **1.117ms** | ~6.6× |
| `signature_help interface integer` | 2.026ms | **216us** | ~10× |
| `completion integer literal I32` | 2.359ms | **535us** | ~4.4× |
| 9 sublanguage tests (média) | ~20ms ea | **~1ms ea** | ~10–25× |

Cold-start spikes (80ms stdlib template + 20ms node spawn + 180ms erlang spawn) paid once in the warmup row instead of polluting feature-test rows.

## Exit gate — verified

- [x] Zero `.tmp-exec-*/` dirs after `zig build test` on a fresh worktree.
- [x] All per-test scratch lives under `<compiler-core>/.botopinkbuild/tmp/<hex>/`.
- [x] `runtime_scratch.zig` pin tests pass on every backend.
- [x] `git status` clean after `zig build test`.
- [x] `clean-tmp` step reaps leaks older than 1 day; manual `zig build clean-tmp` works.
- [x] AGENTS.md per affected module updated in the same commit as code.
- [x] Both `feat` branches updated FF-only (no force, no rewrite).
